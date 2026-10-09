import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

enum PaymentMethod { card, qr }

/// Result of a payment attempt.
class PaymentOutcome {
  final bool success;
  final String? failureReason;

  const PaymentOutcome.success() : success = true, failureReason = null;

  const PaymentOutcome.failure(this.failureReason) : success = false;
}

/// Handles payment processing and card-input validation.
///
/// The payment amount is always derived by the backend from the booking
/// itself, so it is never sent in the request body.
class PaymentService {
  PaymentService._();

  static final PaymentService instance = PaymentService._();

  final Dio _dio = ApiService.instance.dio;

  Future<PaymentOutcome> pay({
    required int bookingId,
    required PaymentMethod method,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.payBooking(bookingId),
        data: {
          'method': method == PaymentMethod.card ? 'CARD' : 'QR',
          if (method == PaymentMethod.card) 'cardNumber': cardNumber,
          if (method == PaymentMethod.card) 'cardHolderName': cardHolderName,
          if (method == PaymentMethod.card) 'expiryDate': expiryDate,
          if (method == PaymentMethod.card) 'cvv': cvv,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      if (data['status']?.toString() == 'SUCCESS') {
        return const PaymentOutcome.success();
      }

      return PaymentOutcome.failure(
        data['failureReason']?.toString() ?? 'Payment failed',
      );
    } on DioException catch (error) {
      return PaymentOutcome.failure(
        ApiService.instance.getErrorMessage(error),
      );
    }
  }

  String? validateCardNumber(String? value) {
    final digits = (value ?? '').replaceAll(' ', '');

    if (digits.length != 16) {
      return 'Enter a valid 16-digit card number';
    }

    return null;
  }

  String? validateCardHolder(String? value) {
    if (value == null || value.trim().length < 3) {
      return 'Enter the name on the card';
    }

    return null;
  }

  String? validateExpiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');

    if (match == null) {
      return 'Use MM/YY';
    }

    final month = int.parse(match.group(1)!);
    final year = int.parse('20${match.group(2)!}');

    if (month < 1 || month > 12) {
      return 'Invalid month';
    }

    final firstDayNextMonth = DateTime(year, month + 1);

    if (firstDayNextMonth.isBefore(DateTime.now())) {
      return 'Card has expired';
    }

    return null;
  }

  String? validateCvv(String? value) {
    final digits = value ?? '';

    if (digits.length < 3 || digits.length > 4) {
      return 'Enter a valid CVV';
    }

    return null;
  }
}
