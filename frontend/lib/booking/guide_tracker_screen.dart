import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';
import 'booking_widgets.dart';

class GuideTrackerScreen extends StatefulWidget {
  final GuideReservation initial;
  const GuideTrackerScreen({super.key, required this.initial});
  @override
  State<GuideTrackerScreen> createState() => _GuideTrackerScreenState();
}

class _GuideTrackerScreenState extends State<GuideTrackerScreen>
    with WidgetsBindingObserver {
  final service = BookingService();
  final code = TextEditingController(),
      etaMinutes = TextEditingController(text: '10');
  late GuideReservation booking;
  late AuthProvider auth;
  late int owner;
  Timer? timer;
  bool offline = false,
      sharing = false,
      refreshing = false,
      acting = false,
      foreground = true,
      revoked = false;
  String? error;
  Position? travelerPosition;
  DateTime? arrivalTarget;
  bool get guide => auth.role == 'GUIDE';
  @override
  void initState() {
    super.initState();
    booking = widget.initial;
    auth = context.read<AuthProvider>();
    owner = auth.user!.id!;
    auth.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
    refresh();
  }

  void accountChanged() {
    if (auth.user?.id != owner) {
      sharing = false;
      timer?.cancel();
      if (mounted) setState(() => revoked = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) sharing = false;
    if (mounted) setState(() {});
    if (foreground) refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    auth.removeListener(accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    code.dispose();
    etaMinutes.dispose();
    super.dispose();
  }

  Future<void> cacheCurrent() async {
    if (auth.user?.id != owner) return;
    final old = await BookingCache.read(owner);
    final list =
        (old['bookings'] as List? ?? [])
            .map((j) => GuideReservation(Json.from(j)))
            .where((b) => b.id != booking.id)
            .toList()
          ..add(booking);
    if (auth.user?.id == owner) await BookingCache.save(owner, list);
  }

  Future<void> refresh() async {
    if (refreshing || !foreground || revoked) return;
    refreshing = true;
    try {
      final updated = await service.get(booking.id);
      if (!mounted || auth.user?.id != owner) return;
      setState(() {
        booking = updated;
        offline = false;
        error = null;
        if (!booking.active) sharing = false;
      });
      await cacheCurrent();
      final cached = await BookingCache.read(owner);
      final pending = (cached['pending'] as Map?)?[booking.id];
      if (pending != null && guide) {
        final result = await service.pin(booking.id, pending.toString());
        await BookingCache.pending(owner, booking.id, null);
        if (mounted) setState(() => error = result['message']);
      }
      if (sharing && booking.active) await publish();
    } catch (e) {
      if (mounted) {
        setState(() {
          offline = true;
          error = ApiService.instance.getErrorMessage(e);
          if (e is DioException &&
              [401, 403, 404].contains(e.response?.statusCode)) {
            revoked = true;
            sharing = false;
            timer?.cancel();
          }
        });
      }
    } finally {
      refreshing = false;
    }
  }

  Future<Position> position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Location services are off. Meeting details remain available.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission denied. Use the meeting schematic and contact your guide.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Future<void> publish() async {
    final p = await position();
    if (!mounted ||
        !foreground ||
        !sharing ||
        auth.user?.id != owner ||
        !booking.active) {
      return;
    }
    final mins = int.tryParse(etaMinutes.text);
    if (mins == null || mins < 1 || mins > 240) {
      throw StateError('ETA must be 1–240 minutes.');
    }
    final updated = await service.location(
      booking.id,
      p.latitude,
      p.longitude,
      (arrivalTarget ??= DateTime.now().add(
            Duration(minutes: mins),
          )).isAfter(DateTime.now())
          ? arrivalTarget
          : null,
    );
    if (mounted) setState(() => booking = updated);
  }

  Future<void> action(Future<void> Function() work) async {
    if (acting) return;
    setState(() {
      acting = true;
      error = null;
    });
    try {
      await work();
      await cacheCurrent();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is StateError
              ? e.message
              : ApiService.instance.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> contact(bool sms) async {
    final phone = booking.json['participantPhone'] as String?;
    if (phone == null || phone.isEmpty) {
      throw StateError(
        'This participant has not supplied a phone number. Ask them to update their profile.',
      );
    }
    final uri = Uri(
      scheme: sms ? 'sms' : 'tel',
      path: phone,
      query: sms
          ? 'body=${Uri.encodeComponent('HISTORIA ${booking.reference}: meeting at ${booking.landmark.name}, ${schedule(booking.json['startsAt'])}.')}'
          : null,
    );
    if (!await launchUrl(uri)) {
      await Clipboard.setData(ClipboardData(text: phone));
      throw StateError(
        'No calling/SMS app available. Phone number copied: $phone',
      );
    }
  }

  Future<void> verify() async {
    if (!RegExp(r'^\d{4}$').hasMatch(code.text)) {
      throw StateError('Enter the four-digit meeting code.');
    }
    if (offline) {
      if (!booking.pinValid || code.text != booking.json['meetingPin']) {
        throw StateError(
          'Code does not match the unexpired cached meeting details.',
        );
      }
      await BookingCache.pending(owner, booking.id, code.text);
      if (mounted) {
        setState(
          () => error =
              'Provisional offline match saved. Online verification is still required; it will retry after reconnection.',
        );
      }
      return;
    }
    final result = await service.pin(booking.id, code.text);
    final updated = await service.get(booking.id);
    if (mounted) {
      setState(() {
        booking = updated;
        error = result['message'];
      });
    }
  }

  Future<void> resumeCheckout() async {
    final c = await service.checkout(booking.id);
    if (!c.demoEnabled) {
      throw StateError('Live checkout awaits member 3 payment integration.');
    }
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Demo checkout · no money collected'),
        content: Text(money(booking.json['amount'])),
        actions: ['success', 'failure', 'cancel']
            .map(
              (v) => TextButton(
                onPressed: () => Navigator.pop(c, v),
                child: Text(v),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) {
      final b = await service.pay(booking.id, result);
      if (mounted) setState(() => booking = b);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (revoked) {
      return BookingShell(
        title: 'Session unavailable',
        nav: false,
        child: const Text('Sign in again to view this booking.'),
      );
    }
    String? distance;
    if (travelerPosition != null &&
        booking.json['latitude'] != null &&
        !booking.stale &&
        !offline) {
      distance =
          '${Geolocator.distanceBetween(travelerPosition!.latitude, travelerPosition!.longitude, (booking.json['latitude'] as num).toDouble(), (booking.json['longitude'] as num).toDouble()).round()} m straight-line from your last position';
    }
    return BookingShell(
      title: booking.state == 'EN_ROUTE'
          ? 'Guide is on the way.'
          : booking.active
          ? 'Your guide & meeting.'
          : 'Booking details',
      subtitle: 'Meet at ${booking.landmark.name}.',
      nav: !guide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${booking.reference} · ${booking.state}',
            style: const TextStyle(fontSize: 12, color: bookingGreen),
          ),
          const SizedBox(height: 12),
          if (offline)
            const Text(
              'OFFLINE · cached meeting details. Live updates unavailable.',
            ),
          errorNotice(error, refresh),
          if (booking.active) ...[
            BookingCard(
              child: Column(
                children: [
                  Text(
                    offline ? 'Updates offline' : booking.countdown,
                    style: const TextStyle(
                      color: bookingGreen,
                      fontFamily: 'monospace',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Arrival estimate',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    distance ??
                        (booking.stale
                            ? 'Waiting for a fresh guide update'
                            : 'Guide location received · distance unavailable'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    booking.json['locationUpdatedAt'] == null
                        ? 'No location update yet'
                        : 'Last update: ${schedule(booking.json['locationUpdatedAt'])}${booking.stale ? ' · STALE' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            CustomPaint(
              painter: _DashedBorder(),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Text(
                      'M E E T I N G   P A S S C O D E',
                      style: TextStyle(fontSize: 11, color: bookingGreen),
                    ),
                    Text(
                      booking.json['pinUsed'] == true
                          ? 'Verified'
                          : booking.pinValid
                          ? '# ${booking.json['meetingPin']}'
                          : 'Expired / unavailable',
                      style: const TextStyle(
                        fontSize: 28,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: bookingGreen,
                      ),
                    ),
                    const Text(
                      'Compare in person. Offline matches are provisional.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          BookingCard(
            child: Column(
              children: [
                detailRow('ASSIGNED GUIDE', booking.guide),
                detailRow('Meeting time', schedule(booking.json['startsAt'])),
                detailRow('Package', booking.json['packageName']),
                detailRow('Party size', '${booking.json['visitors']} visitors'),
                detailRow(
                  'Total · ${booking.json['paymentState']}',
                  money(booking.json['amount']),
                ),
              ],
            ),
          ),
          if (booking.state == 'HELD' && !guide)
            bookingButton(
              'Resume checkout',
              acting || offline ? null : () => action(resumeCheckout),
            ),
          if (booking.active) ...[
            bookingButton(
              guide ? 'Call traveler' : '☎  Call Guide',
              acting ? null : () => action(() => contact(false)),
            ),
            bookingButton(
              'Message · SMS',
              acting ? null : () => action(() => contact(true)),
              outlined: true,
            ),
          ],
          if (!guide && booking.active)
            TextButton(
              onPressed: acting
                  ? null
                  : () => action(() async {
                      final p = await position();
                      if (mounted) setState(() => travelerPosition = p);
                    }),
              child: const Text('Use my location for straight-line distance'),
            ),
          if (guide && booking.active) ...[
            const Divider(),
            const Text(
              'Guide controls',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: etaMinutes,
              onChanged: (_) {
                arrivalTarget = null;
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Arrival estimate (minutes)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share foreground location'),
              subtitle: const Text(
                'Stops when you leave this screen or put the app in the background.',
              ),
              value: sharing,
              onChanged:
                  acting ||
                      ![
                        'EN_ROUTE',
                        'ARRIVED',
                        'IN_PROGRESS',
                      ].contains(booking.state)
                  ? null
                  : (v) => action(() async {
                      setState(() {
                        sharing = v;
                        arrivalTarget = null;
                      });
                      if (v) {
                        try {
                          await publish();
                        } catch (_) {
                          if (mounted) setState(() => sharing = false);
                          rethrow;
                        }
                      }
                    }),
            ),
            if (booking.state == 'ARRIVED' &&
                booking.json['pinUsed'] != true) ...[
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Traveler meeting code',
                ),
              ),
              bookingButton(
                offline
                    ? 'Compare offline (provisional)'
                    : 'Confirm meeting code',
                acting ? null : () => action(verify),
              ),
            ],
            bookingButton(
              switch (booking.state) {
                'CONFIRMED' => 'Set en route',
                'EN_ROUTE' => 'Set arrived',
                'ARRIVED' => 'Start visit',
                _ => 'Complete visit',
              },
              acting || offline
                  ? null
                  : () => action(() async {
                      final b = await service.state(
                        booking.id,
                        switch (booking.state) {
                          'CONFIRMED' => 'EN_ROUTE',
                          'EN_ROUTE' => 'ARRIVED',
                          'ARRIVED' => 'IN_PROGRESS',
                          _ => 'COMPLETED',
                        },
                      );
                      if (mounted) {
                        setState(() {
                          booking = b;
                          if (!booking.active) sharing = false;
                        });
                      }
                    }),
            ),
          ],
          ExpansionTile(
            title: const Text('Offline meeting details'),
            children: [
              MeetingMap(landmark: booking.landmark),
              Text(booking.landmark.description),
              Text(booking.landmark.access),
            ],
          ),
          if ([
            'HELD',
            'CONFIRMED',
            'EN_ROUTE',
            'ARRIVED',
          ].contains(booking.state))
            TextButton(
              onPressed: acting || offline
                  ? null
                  : () => action(() async {
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Cancel this booking?'),
                          content: const Text(
                            'Paid bookings are marked for refund handling by the payment team.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Keep booking'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Cancel booking'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true) {
                        final b = await service.state(booking.id, 'CANCELLED');
                        if (mounted) {
                          setState(() {
                            booking = b;
                            sharing = false;
                          });
                        }
                      }
                    }),
              child: const Text('Cancel booking'),
            ),
        ],
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    final paint = Paint()
      ..color = bookingGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double i = 0; i < metric.length; i += 10) {
        canvas.drawPath(metric.extractPath(i, i + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}
