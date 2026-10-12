import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/historia_components.dart';
import '../tourist/tour_planner_screen.dart';
import '../tourist/create_post_screen.dart';
import '../tourist/historical_search_screen.dart';
import '../profile/profile_screen.dart';
import '../screens/home_router.dart';
import 'booking_models.dart';

const bookingGreen = Color(0xFF174F3B);
const bookingBorder = Color(0xFFE1E7E7);

class BookingShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? back;
  final bool nav;
  const BookingShell({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.child,
    this.actions = const [],
    this.back,
    this.nav = true,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFBF8),
    bottomNavigationBar: nav
        ? HistoriaBottomNavigation(
            currentIndex: 4,
            items: const [
              HistoriaNavItem(icon: Icons.home_outlined, label: 'Home'),
              HistoriaNavItem(icon: Icons.map_outlined, label: 'Tour'),
              HistoriaNavItem(icon: Icons.edit_square, label: 'Create'),
              HistoriaNavItem(icon: Icons.explore_outlined, label: 'Explore'),
              HistoriaNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
            onTap: (index) {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeRouter()),
                  (r) => false,
                );
                return;
              }
              final destination = switch (index) {
                1 => const TourPlannerScreen(),
                2 => const CreatePostScreen(),
                3 => const HistoricalSearchScreen(),
                _ => const ProfileScreen(),
              };
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            },
          )
        : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: bookingBorder)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: back ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    const HistoriaLogoMark(size: 32),
                    const SizedBox(width: 8),
                    const Expanded(child: HistoriaBrandText()),
                    ...actions,
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: ValueKey(title),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: bookingGreen,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 18),
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF748096),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class BookingCard extends StatelessWidget {
  final Widget child;
  final bool selected;
  const BookingCard({super.key, required this.child, this.selected = false});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFF2F8F3) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? bookingGreen : bookingBorder,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: child,
  );
}

Widget bookingButton(
  String label,
  VoidCallback? onPressed, {
  bool outlined = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: SizedBox(
    width: double.infinity,
    height: 50,
    child: outlined
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: bookingGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            child: Text(label),
          ),
  ),
);
Widget detailRow(String name, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          name,
          style: const TextStyle(color: Color(0xFF738198), fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  ),
);
Widget errorNotice(String? message, VoidCallback retry) => message == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(message, style: const TextStyle(color: Colors.deepOrange)),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );

class MeetingMap extends StatefulWidget {
  final Landmark landmark;
  const MeetingMap({super.key, required this.landmark});
  @override
  State<MeetingMap> createState() => _MeetingMapState();
}

class _MeetingMapState extends State<MeetingMap> {
  final mapController = MapController();
  static const double _initialZoom = 16.6;
  static const double _minZoom = 14;
  static const double _maxZoom = 18.5;
  static const int _fallbackTileErrorThreshold = 3;

  double zoom = _initialZoom;
  int tileErrorCount = 0;
  bool tilesFailed = false;

  static final Map<String, _LandmarkMapPoint> landmarkPoints = {
    'clock': _LandmarkMapPoint(
      name: 'Clock Tower Gate',
      position: LatLng(6.03003, 80.21508),
    ),
    'moon': _LandmarkMapPoint(
      name: 'Moon Bastion',
      position: LatLng(6.03046, 80.21502),
    ),
    'sun': _LandmarkMapPoint(
      name: 'Sun Bastion',
      position: LatLng(6.03041, 80.21685),
    ),
  };

  _LandmarkMapPoint get point =>
      landmarkPoints[widget.landmark.id] ??
      _LandmarkMapPoint(
        name: widget.landmark.name,
        position: const LatLng(6.0274, 80.21677),
      );

  @override
  void didUpdateWidget(covariant MeetingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.landmark.id == widget.landmark.id) {
      return;
    }

    zoom = _initialZoom;
    tileErrorCount = 0;
    tilesFailed = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        mapController.move(point.position, zoom);
      }
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  void scale(double delta) {
    final nextZoom = (zoom + delta).clamp(_minZoom, _maxZoom);

    setState(() {
      zoom = nextZoom;
    });

    mapController.move(point.position, zoom);
  }

  void handleTileError() {
    if (!mounted || tilesFailed) {
      return;
    }

    tileErrorCount += 1;

    if (tileErrorCount >= _fallbackTileErrorThreshold) {
      setState(() {
        tilesFailed = true;
      });
    }
  }

  Future<void> openInMaps() async {
    final selected = point;
    final query =
        '${selected.position.latitude},${selected.position.longitude}';
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (opened) {
        return;
      }

      final openedFallback = await launchUrl(uri);

      if (!openedFallback && mounted) {
        showMapError();
      }
    } catch (_) {
      if (mounted) {
        showMapError();
      }
    }
  }

  void showMapError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps.'),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 210,
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: point.position,
                    initialZoom: zoom,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                    backgroundColor: const Color(0xFFF3F2EB),
                    onPositionChanged: (camera, _) {
                      zoom = camera.zoom;
                    },
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.scrollWheelZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.historia.frontend',
                      errorTileCallback: (_, _, _) => handleTileError(),
                      evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point.position,
                          width: 58,
                          height: 70,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: bookingGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: bookingGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (tilesFailed)
                Positioned.fill(
                  child: _OfflineMapFallback(
                    landmark: widget.landmark,
                    pointName: point.name,
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 72,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE1E7E7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, color: bookingGreen, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          point.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: bookingGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Column(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Zoom in',
                      onPressed: () => scale(.3),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Zoom out',
                      onPressed: () => scale(-.3),
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 9,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Map data from OpenStreetMap',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF66746B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Open in Google Maps',
                      child: FilledButton.icon(
                        onPressed: openInMaps,
                        icon: const Icon(Icons.near_me_outlined, size: 16),
                        label: const Text('Google Maps'),
                        style: FilledButton.styleFrom(
                          backgroundColor: bookingGreen,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        tilesFailed
            ? 'Offline schematic - ${widget.landmark.name}'
            : 'OpenStreetMap - ${widget.landmark.name}',
        style: const TextStyle(fontSize: 11, color: Color(0xFF66746B)),
      ),
    ],
  );
}

class _LandmarkMapPoint {
  final String name;
  final LatLng position;

  const _LandmarkMapPoint({required this.name, required this.position});
}

class _OfflineMapFallback extends StatelessWidget {
  final Landmark landmark;
  final String pointName;

  const _OfflineMapFallback({required this.landmark, required this.pointName});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xFFF3F2EB)),
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _FortFallbackPainter(landmark)),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bookingBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: bookingGreen, size: 22),
                const SizedBox(height: 6),
                const Text(
                  'Map tiles need internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: bookingGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Showing schematic for $pointName.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF66746B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _FortFallbackPainter extends CustomPainter {
  final Landmark landmark;

  _FortFallbackPainter(this.landmark);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF3F2EB),
    );

    final path = ui.Path()
      ..moveTo(size.width * .14, size.height * .35)
      ..lineTo(size.width * .26, size.height * .19)
      ..lineTo(size.width * .8, size.height * .23)
      ..lineTo(size.width * .9, size.height * .43)
      ..lineTo(size.width * .86, size.height * .8)
      ..lineTo(size.width * .68, size.height * .79)
      ..lineTo(size.width * .57, size.height * .94)
      ..lineTo(size.width * .47, size.height * .78)
      ..lineTo(size.width * .16, size.height * .8)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFDDE8D9));
    canvas.drawPath(
      path,
      Paint()
        ..color = bookingGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 2; j++) {
        final rect = Rect.fromLTWH(
          size.width * (.23 + i * .18),
          size.height * (.4 + j * .2),
          size.width * .15,
          size.height * .14,
        );
        canvas.drawRect(rect, Paint()..color = Colors.white);
        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFF8193A9)
            ..style = PaintingStyle.stroke,
        );
      }
    }

    final pin = Offset(size.width * landmark.x, size.height * landmark.y);
    canvas.drawCircle(pin, 18, Paint()..color = Colors.white);
    canvas.drawCircle(pin, 13, Paint()..color = bookingGreen);
    canvas.drawCircle(pin, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_FortFallbackPainter oldDelegate) =>
      oldDelegate.landmark.id != landmark.id;
}
