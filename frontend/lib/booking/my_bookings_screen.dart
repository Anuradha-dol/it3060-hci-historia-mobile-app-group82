import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';
import 'booking_widgets.dart';
import 'guide_tracker_screen.dart';
import 'guide_management_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<GuideReservation> bookings = [];
  bool busy = true, offline = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final owner = context.read<AuthProvider>().user?.id;
    if (owner == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await BookingService().mine();
      if (!mounted || context.read<AuthProvider>().user?.id != owner) return;
      await BookingCache.save(owner, result);
      if (mounted) {
        setState(() {
          bookings = result;
          offline = false;
        });
      }
    } catch (e) {
      if (e is DioException && [401, 403].contains(e.response?.statusCode)) {
        if (mounted) {
          setState(() {
            bookings = [];
            error = 'Sign in again to access your bookings.';
          });
        }
        return;
      }
      final cache = await BookingCache.read(owner);
      if (mounted) {
        setState(() {
          offline = true;
          error = ApiService.instance.getErrorMessage(e);
          bookings = (cache['bookings'] as List? ?? [])
              .map((j) => GuideReservation(Json.from(j)))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = context.watch<AuthProvider>().role == 'GUIDE';
    return BookingShell(
      title: 'My guide bookings',
      subtitle: 'Upcoming visits, meeting details and booking history.',
      nav: !guide,
      actions: [
        IconButton(
          tooltip: 'Refresh bookings',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: Column(
        children: [
          if (guide)
            bookingButton(
              'Manage packages & availability',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GuideManagementScreen(),
                ),
              ),
            ),
          if (offline)
            const Text(
              'OFFLINE / cached details · reconnect to confirm changes',
            ),
          errorNotice(error, load),
          if (busy)
            const CircularProgressIndicator()
          else if (bookings.isEmpty)
            const BookingCard(
              child: Text(
                'No guide bookings yet. Select a guide to plan your visit.',
              ),
            ),
          ...bookings.map(
            (b) => BookingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${b.reference} · ${b.state}',
                    style: const TextStyle(
                      color: bookingGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  detailRow(b.guide, b.json['packageName']),
                  Text(schedule(b.json['startsAt'])),
                  Text('${b.landmark.name} · ${money(b.json['amount'])}'),
                  bookingButton('Open booking', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuideTrackerScreen(initial: b),
                      ),
                    );
                    if (mounted) load();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
