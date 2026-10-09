import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HistoriaFooterArt extends StatelessWidget {
  final double height;
  final String? caption;

  const HistoriaFooterArt({super.key, this.height = 74, this.caption});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _HistoriaFooterPainter(),
        child: caption == null
            ? null
            : Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 22, top: 8),
                  child: Text(
                    caption!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _HistoriaFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = AppColors.primarySoft;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.44, size.width, size.height),
      sky,
    );

    final sun = Paint()..color = const Color(0xFFF2D781);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.44), 6, sun);

    final backHill = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.45,
        size.width * 0.32,
        size.height * 0.74,
        size.width * 0.48,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.28,
        size.width * 0.80,
        size.height * 0.62,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(backHill, Paint()..color = const Color(0xFFCFE5D8));

    final frontHill = Path()
      ..moveTo(0, size.height * 0.86)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.62,
        size.width * 0.28,
        size.height * 0.95,
        size.width * 0.42,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.52,
        size.width * 0.72,
        size.height * 0.90,
        size.width,
        size.height * 0.64,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(frontHill, Paint()..color = const Color(0xFFAFCFBD));

    final dark = Paint()..color = AppColors.primary.withValues(alpha: 0.72);
    _drawTemple(
      canvas,
      Offset(size.width * 0.07, size.height * 0.56),
      size.height * 0.34,
      dark,
    );
    _drawPagoda(
      canvas,
      Offset(size.width * 0.42, size.height * 0.63),
      size.height * 0.24,
      dark,
    );
    _drawTemple(
      canvas,
      Offset(size.width * 0.88, size.height * 0.58),
      size.height * 0.30,
      dark,
    );

    final tree = Paint()..color = AppColors.primaryDark.withValues(alpha: 0.38);
    for (var i = 0; i < 18; i++) {
      final x = size.width * i / 17;
      final h = (i.isEven ? 11 : 16).toDouble();
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.height - h),
          width: 22,
          height: h + 8,
        ),
        tree,
      );
    }

    final bird = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final offset in [
      Offset(size.width * 0.80, size.height * 0.24),
      Offset(size.width * 0.84, size.height * 0.19),
      Offset(size.width * 0.76, size.height * 0.16),
    ]) {
      final path = Path()
        ..moveTo(offset.dx - 4, offset.dy)
        ..quadraticBezierTo(offset.dx, offset.dy - 3, offset.dx + 4, offset.dy);
      canvas.drawPath(path, bird);
    }
  }

  void _drawTemple(Canvas canvas, Offset origin, double height, Paint paint) {
    final baseY = origin.dy + height;
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx,
        baseY - height * 0.38,
        height * 0.48,
        height * 0.38,
      ),
      paint,
    );
    final roof = Path()
      ..moveTo(origin.dx - height * 0.05, baseY - height * 0.38)
      ..lineTo(origin.dx + height * 0.24, baseY - height * 0.68)
      ..lineTo(origin.dx + height * 0.53, baseY - height * 0.38)
      ..close();
    canvas.drawPath(roof, paint);
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx + height * 0.16,
        baseY - height * 0.25,
        height * 0.16,
        height * 0.25,
      ),
      Paint()..color = AppColors.background.withValues(alpha: 0.65),
    );
  }

  void _drawPagoda(Canvas canvas, Offset origin, double height, Paint paint) {
    for (var i = 0; i < 4; i++) {
      final y = origin.dy + i * height * 0.18;
      final w = height * (0.72 - i * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(origin.dx, y),
            width: w,
            height: height * 0.12,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx - height * 0.08,
        origin.dy,
        height * 0.16,
        height * 0.58,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
