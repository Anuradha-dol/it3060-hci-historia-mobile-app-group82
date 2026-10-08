import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking_summary_model.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'payment_result_screen.dart';

/// Booking Checkout & Payment Option screen.
///
/// Lets the tourist review the confirmed booking, choose between Card and
/// QR payment, and pay. On completion it pushes [PaymentResultScreen] with
/// the outcome.
class CheckoutScreen extends StatefulWidget {
  final BookingSummary booking;

  const CheckoutScreen({super.key, required this.booking});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _paymentService = PaymentService.instance;

  PaymentMethod _method = PaymentMethod.card;
  bool _submitting = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _resetCardForm() {
    setState(() {
      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryController.clear();
      _cvvController.clear();
    });
  }

  void _selectMethod(PaymentMethod method) {
    if (_method == method) return;
    setState(() => _method = method);
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onPay() async {
    if (_method == PaymentMethod.card &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bookingId = widget.booking.id;

    if (bookingId == null) {
      showAppMessage(context, 'This booking is not ready for checkout.', error: true);
      return;
    }

    setState(() => _submitting = true);

    final outcome = await _paymentService.pay(
      bookingId: bookingId,
      method: _method,
      cardNumber: _method == PaymentMethod.card
          ? _cardNumberController.text
          : null,
      cardHolderName: _method == PaymentMethod.card
          ? _cardHolderController.text
          : null,
      expiryDate: _method == PaymentMethod.card
          ? _expiryController.text
          : null,
      cvv: _method == PaymentMethod.card ? _cvvController.text : null,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    final action = await Navigator.push<PaymentResultAction>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          booking: widget.booking,
          outcome: outcome,
          method: _method,
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == PaymentResultAction.retry) {
      _onPay();
    } else if (action == PaymentResultAction.changeMethod) {
      setState(() {
        _method = _method == PaymentMethod.card
            ? PaymentMethod.qr
            : PaymentMethod.card;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            HistoriaHeader(
              title: 'Checkout',
              eyebrow: 'BOOKING PAYMENT',
              subtitle: 'Review your booking and pay securely to confirm it.',
              icon: Icons.credit_card_outlined,
              actions: [
                HistoriaIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: _goHome,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  HistoriaInfoBox(
                    title: 'Your booking',
                    message:
                        '${booking.guideName} • ${booking.dateLabel} • '
                        '${booking.placesCount} places • ${booking.durationLabel}',
                    icon: Icons.event_available_outlined,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total  ${booking.amountLabel}',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PaymentMethodTabs(
                    method: _method,
                    onChanged: _selectMethod,
                  ),
                  const SizedBox(height: 18),
                  if (_method == PaymentMethod.card)
                    _CardPaymentForm(
                      formKey: _formKey,
                      cardNumberController: _cardNumberController,
                      cardHolderController: _cardHolderController,
                      expiryController: _expiryController,
                      cvvController: _cvvController,
                      onAddNewCard: _resetCardForm,
                      paymentService: _paymentService,
                    )
                  else
                    _QrPaymentView(
                      amount: booking.amount,
                      currency: booking.currency,
                    ),
                  const SizedBox(height: 26),
                  AsyncButton(
                    loading: _submitting,
                    label: 'Pay ${booking.amountLabel}',
                    icon: Icons.lock_outline_rounded,
                    onPressed: _submitting ? null : _onPay,
                  ),
                ],
              ),
            ),
            HistoriaBottomNavigation(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) _goHome();
              },
              items: const [
                HistoriaNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                ),
                HistoriaNavItem(icon: Icons.map_outlined, label: 'Tour'),
                HistoriaNavItem(icon: Icons.edit_outlined, label: 'Create'),
                HistoriaNavItem(
                  icon: Icons.explore_outlined,
                  label: 'Explore',
                ),
                HistoriaNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTabs extends StatelessWidget {
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodTabs({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab('Card', Icons.credit_card_rounded, PaymentMethod.card),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tab(
              'QR Code',
              Icons.qr_code_2_rounded,
              PaymentMethod.qr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, IconData icon, PaymentMethod value) {
    final active = method == value;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPaymentForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cardNumberController;
  final TextEditingController cardHolderController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final VoidCallback onAddNewCard;
  final PaymentService paymentService;

  const _CardPaymentForm({
    required this.formKey,
    required this.cardNumberController,
    required this.cardHolderController,
    required this.expiryController,
    required this.cvvController,
    required this.onAddNewCard,
    required this.paymentService,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Add a card', style: AppTextStyles.sectionTitle),
              ),
              TextButton(
                onPressed: onAddNewCard,
                child: const Text('Add new card'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: Listenable.merge([
              cardNumberController,
              cardHolderController,
            ]),
            builder: (context, _) => _CardPreview(
              number: cardNumberController.text,
              holder: cardHolderController.text,
            ),
          ),
          const SizedBox(height: 18),
          _PaymentField(
            label: 'Card Number',
            controller: cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [_CardNumberFormatter()],
            validator: paymentService.validateCardNumber,
          ),
          const SizedBox(height: 14),
          _PaymentField(
            label: 'Card Holder Name',
            controller: cardHolderController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: paymentService.validateCardHolder,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PaymentField(
                  label: 'Expiry Date',
                  hintText: 'MM/YY',
                  controller: expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ExpiryDateFormatter()],
                  validator: paymentService.validateExpiry,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PaymentField(
                  label: 'CVV',
                  controller: cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: paymentService.validateCvv,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const _PaymentField({
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: AppColors.primaryDark,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            filled: true,
            fillColor: AppColors.mint.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String number;
  final String holder;

  const _CardPreview({required this.number, required this.holder});

  @override
  Widget build(BuildContext context) {
    final displayNumber = number.isEmpty
        ? '•••• •••• •••• ••••'
        : number.padRight(19, '•').substring(0, 19);
    final displayHolder = holder.trim().isEmpty
        ? 'CARD HOLDER NAME'
        : holder.toUpperCase();

    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F3F), Color(0xFF17417A), Color(0xFF2F6FCB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C468),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.sim_card_outlined,
                  size: 14,
                  color: Colors.brown.shade700,
                ),
              ),
              const Spacer(),
              const Text(
                'ATM CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayHolder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDFF3E6),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPaymentView extends StatelessWidget {
  final double amount;
  final String currency;

  const _QrPaymentView({required this.amount, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Scan QR Code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 210,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Scan this code with your banking app to pay '
          '$currency ${amount.toStringAsFixed(0)}.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i + 1) % 4 == 0 && i + 1 != limited.length) {
        buffer.write(' ');
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;

    final text = limited.length >= 3
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
