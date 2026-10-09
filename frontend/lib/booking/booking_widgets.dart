import 'package:flutter/material.dart';
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
  final transform = TransformationController();
  double zoom = 1;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void scale(double delta) {
    zoom = (zoom + delta).clamp(1, 3);
    transform.value = Matrix4.diagonal3Values(zoom, zoom, 1);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 175,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: transform,
                  minScale: 1,
                  maxScale: 3,
                  child: CustomPaint(
                    painter: _FortPainter(widget.landmark),
                    child: const SizedBox.expand(),
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
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Galle Fort schematic · ${widget.landmark.name}',
        style: const TextStyle(fontSize: 11, color: Color(0xFF66746B)),
      ),
    ],
  );
}

class _FortPainter extends CustomPainter {
  final Landmark landmark;
  _FortPainter(this.landmark);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF3F2EB),
    );
    final path = Path()
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
    canvas.drawCircle(pin, 16, Paint()..color = Colors.white);
    canvas.drawCircle(pin, 12, Paint()..color = bookingGreen);
    canvas.drawCircle(pin, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_FortPainter oldDelegate) =>
      oldDelegate.landmark.id != landmark.id;
}
