import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/payment_service.dart';
import 'booking_models.dart';
import 'booking_service.dart';
import 'booking_widgets.dart';

class GuidePaymentScreen extends StatefulWidget {
  final CheckoutContract contract;

  const GuidePaymentScreen({super.key, required this.contract});

  @override
  State<GuidePaymentScreen> createState() => _GuidePaymentScreenState();
}

class _GuidePaymentScreenState extends State<GuidePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _paymentService = PaymentService.instance;
  final _bookingService = BookingService();

  PaymentMethod _method = PaymentMethod.card;
  bool _submitting = false;

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_method == PaymentMethod.card &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final booking = await _bookingService.pay(
        widget.contract.bookingId,
        method: _method,
        cardNumber: _method == PaymentMethod.card ? _cardNumber.text : null,
        cardHolderName: _method == PaymentMethod.card ? _cardHolder.text : null,
        expiryDate: _method == PaymentMethod.card ? _expiry.text : null,
        cvv: _method == PaymentMethod.card ? _cvv.text : null,
      );

      if (!mounted) return;
      Navigator.pop(context, booking);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.instance.getErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contract = widget.contract;
    final amount =
        '${contract.currency} ${money(contract.amount).replaceFirst('LKR ', '')}';

    return BookingShell(
      title: 'Payment',
      subtitle: 'Choose card or QR payment to confirm ${contract.reference}.',
      nav: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingCard(
            child: Column(
              children: [
                detailRow('Booking', contract.reference),
                detailRow('Guide', contract.guide),
                detailRow('Package', contract.packageName),
                detailRow('Schedule', schedule(contract.startsAt)),
                detailRow('Party size', '${contract.visitors} visitors'),
                const Divider(),
                detailRow('Total payable', amount),
                detailRow('Hold expires', schedule(contract.expiresAt)),
              ],
            ),
          ),
          const Text(
            'PAYMENT METHOD',
            style: TextStyle(
              color: bookingGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.card,
                icon: Icon(Icons.credit_card),
                label: Text('Card'),
              ),
              ButtonSegment(
                value: PaymentMethod.qr,
                icon: Icon(Icons.qr_code_2),
                label: Text('QR'),
              ),
            ],
            selected: {_method},
            onSelectionChanged: _submitting
                ? null
                : (value) {
                    setState(() {
                      _method = value.first;
                    });
                  },
          ),
          const SizedBox(height: 16),
          if (_method == PaymentMethod.card)
            _cardForm()
          else
            _qrPayment(amount),
          bookingButton(
            _submitting ? 'Processing payment...' : 'Pay $amount',
            _submitting ? null : _pay,
          ),
        ],
      ),
    );
  }

  Widget _cardForm() {
    return Form(
      key: _formKey,
      child: BookingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: bookingGreen, size: 18),
                SizedBox(width: 8),
                Text(
                  'Card payment',
                  style: TextStyle(
                    color: bookingGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PaymentField(
              label: 'Card number',
              controller: _cardNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [_CardNumberFormatter()],
              validator: _paymentService.validateCardNumber,
            ),
            const SizedBox(height: 12),
            _PaymentField(
              label: 'Card holder name',
              controller: _cardHolder,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: _paymentService.validateCardHolder,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PaymentField(
                    label: 'Expiry',
                    hintText: 'MM/YY',
                    controller: _expiry,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ExpiryDateFormatter()],
                    validator: _paymentService.validateExpiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentField(
                    label: 'CVV',
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _paymentService.validateCvv,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrPayment(String amount) {
    return BookingCard(
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 180, color: bookingGreen),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              color: bookingGreen,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan with your banking app, then tap Pay to confirm the booking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64736C), fontSize: 12),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      obscureText: obscureText,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: '',
      ),
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
