import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/booking_summary_model.dart';
import 'api_service.dart';

/// Fetches and creates bookings.
///
/// The real booking/scheduling flow is owned by another module. Until it
/// exists, [createDemoBooking] asks the backend for a sample booking against
/// an approved guide so the checkout, payment and review flows can be
/// exercised end-to-end.
class BookingService {
  final Dio _dio = ApiService.instance.dio;

  Future<BookingSummary> getBooking(int bookingId) async {
    final response = await _dio.get(ApiConfig.bookingById(bookingId));

    return BookingSummary.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<BookingSummary>> getMyBookings() async {
    final response = await _dio.get(ApiConfig.myBookings);

    final List<dynamic> data = response.data;

    return data
        .map(
          (item) => BookingSummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<BookingSummary> createDemoBooking() async {
    final response = await _dio.post(ApiConfig.createDemoBooking);

    return BookingSummary.fromJson(Map<String, dynamic>.from(response.data));
  }
}
