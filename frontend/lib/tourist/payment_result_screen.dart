import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/booking_summary_model.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/historia_components.dart';

/// Action the tourist chose from the unsuccessful-payment screen.
enum PaymentResultAction { retry, changeMethod }

/// Shows the outcome of a payment attempt: success (with booking summary,
/// "View Booking" and "Receipt" actions) or failure (with a reason and
/// "Retry" / "Change Method" actions).
class PaymentResultScreen extends StatelessWidget {
  final BookingSummary booking;
  final PaymentOutcome outcome;
  final PaymentMethod method;

  const PaymentResultScreen({
    super.key,
    required this.booking,
    required this.outcome,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: HistoriaBrandRow(
                actions: [
                  HistoriaIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: outcome.success
                  ? _SuccessView(booking: booking)
                  : _FailureView(
                      reason: outcome.failureReason ?? 'Unknown error',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final BookingSummary booking;

  const _SuccessView({required this.booking});

  void _showReceipt(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Receipt', style: AppTextStyles.title),
            const SizedBox(height: 14),
            _receiptRow('Guide', booking.guideName),
            _receiptRow('Date', booking.dateLabel),
            _receiptRow('Places', '${booking.placesCount}'),
            _receiptRow('Duration', booking.durationLabel),
            const Divider(height: 28),
            _receiptRow('Total Paid', booking.amountLabel, emphasize: true),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMuted),
          Text(
            value,
            style: emphasize
                ? AppTextStyles.sectionTitle
                : AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        const _SealCheckmark(),
        const SizedBox(height: 18),
        const Text(
          'Payment Successful',
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 6),
        Text(
          'Your booking with ${booking.guideName} is confirmed.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 22),
        _SummaryChips(booking: booking),
        const SizedBox(height: 26),
        HistoriaButton(
          label: 'View Booking',
          icon: Icons.calendar_month_outlined,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        const SizedBox(height: 12),
        HistoriaButton(
          label: 'Receipt',
          icon: Icons.receipt_long_outlined,
          onPressed: () => _showReceipt(context),
        ),
      ],
    );
  }
}

class _SealCheckmark extends StatelessWidget {
  const _SealCheckmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(160, 160),
              painter: _ScallopPainter(
                color: AppColors.success.withValues(alpha: 0.85),
              ),
            ),
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            const Icon(Icons.check_rounded, color: Colors.white, size: 56),
          ],
        ),
      ),
    );
  }
}

class _ScallopPainter extends CustomPainter {
  final Color color;

  const _ScallopPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;
    const bumps = 14;
    const bumpDepth = 0.09;

    final path = Path();
    for (var i = 0; i <= 360; i++) {
      final angle = i * math.pi / 180;
      final wave = 1 + bumpDepth * math.cos(bumps * angle);
      final radius = baseRadius * wave;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScallopPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SummaryChips extends StatelessWidget {
  final BookingSummary booking;

  const _SummaryChips({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _chipItem(Icons.calendar_today_outlined, booking.dateLabel),
          _divider(),
          _chipItem(Icons.place_outlined, '${booking.placesCount} places'),
          _divider(),
          _chipItem(Icons.schedule_outlined, booking.durationLabel),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 16, color: Colors.white24);

  Widget _chipItem(IconData icon, String label) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String reason;

  const _FailureView({required this.reason});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Payment Unsuccessful',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('Reason : $reason', style: AppTextStyles.body),
        ),
        const SizedBox(height: 48),
        HistoriaButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () =>
              Navigator.of(context).pop(PaymentResultAction.retry),
        ),
        const SizedBox(height: 14),
        HistoriaButton(
          label: 'Change Method',
          icon: Icons.swap_horiz_rounded,
          onPressed: () =>
              Navigator.of(context).pop(PaymentResultAction.changeMethod),
        ),
      ],
    );
  }
}
