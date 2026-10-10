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
              child: Stack(
                children: [
                  // Background Image - Full Screen
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(child: Container(color: AppColors.background)),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/home_banner.jpg'),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Secure Payment Processing',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 200),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Booking Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Guide Info
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tour Guide',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.guideName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(height: 1, color: AppColors.border),
                            const SizedBox(height: 16),

                            // Details Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _bookingDetail(
                                  Icons.calendar_today_rounded,
                                  'Date',
                                  booking.dateLabel,
                                ),
                                _bookingDetail(
                                  Icons.place_rounded,
                                  'Places',
                                  '${booking.placesCount}',
                                ),
                                _bookingDetail(
                                  Icons.schedule_rounded,
                                  'Duration',
                                  booking.durationLabel,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(height: 1, color: AppColors.border),
                            const SizedBox(height: 16),

                            // Total Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  booking.amountLabel,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Payment Method Section
                      const Text(
                        'Choose Payment Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentMethodTabs(
                        method: _method,
                        onChanged: _selectMethod,
                      ),
                      const SizedBox(height: 24),

                      // Payment Form
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

/// Helper widget to display booking details
Widget _bookingDetail(IconData icon, String label, String value) {
  return Flexible(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
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
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.mint, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Add Card Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddNewCard,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'New',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Card Preview
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.mint, width: 1),
                right: BorderSide(color: AppColors.mint, width: 1),
                bottom: BorderSide(color: AppColors.mint, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                cardNumberController,
                cardHolderController,
              ]),
              builder: (context, _) => _CardPreview(
                number: cardNumberController.text,
                holder: cardHolderController.text,
              ),
            ),
          ),

          // Form Fields Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(color: AppColors.mint, width: 1),
                right: BorderSide(color: AppColors.mint, width: 1),
                bottom: BorderSide(color: AppColors.mint, width: 1),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: paymentService.validateCvv,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentField extends StatefulWidget {
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
  State<_PaymentField> createState() => _PaymentFieldState();
}

class _PaymentFieldState extends State<_PaymentField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          obscureText: widget.obscureText,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: _isFocused
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.mint.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.danger,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 172,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
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
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.sim_card_outlined,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                'HISTORIA CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayHolder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Scan QR Code to Pay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 220,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_rounded,
                size: 18,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Open your banking app and scan this QR code to complete the payment.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.info,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
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
