import 'package:flutter/foundation.dart';

class ApiConfig {
  // ------------------------------------------------------------
  // BASE URL
  // ------------------------------------------------------------

  static String get baseUrl {
    // Flutter Web / Chrome
    if (kIsWeb) {
      return 'http://192.168.1.4:8081';
    }

    // Android Emulator
    return 'http://10.0.2.2:8081';
  }

  static String resolveImageUrl(String? value) {
    final cleaned = value?.trim().replaceAll('\\', '/') ?? '';

    if (cleaned.isEmpty) {
      return '';
    }

    final apiBase = Uri.parse(baseUrl);
    final parsed = Uri.tryParse(cleaned);

    if (parsed != null && parsed.hasScheme) {
      if (parsed.host == 'localhost' ||
          parsed.host == '127.0.0.1' ||
          parsed.host == '10.0.2.2') {
        return parsed
            .replace(
              scheme: apiBase.scheme,
              host: apiBase.host,
              port: apiBase.port,
            )
            .toString();
      }

      return cleaned;
    }

    if (cleaned.startsWith('/')) {
      return '$baseUrl$cleaned';
    }

    if (cleaned.startsWith('uploads/')) {
      return '$baseUrl/$cleaned';
    }

    return cleaned;
  }

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------

  static const String register = '/api/auth/register';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String googleLogin = '/api/auth/google';

  // ------------------------------------------------------------
  // PASSWORD
  // ------------------------------------------------------------

  static const String forgotPassword = '/api/auth/password/forgot';

  static const String verifyForgotPassword = '/api/auth/password/verify';

  static const String resendForgotPasswordOtp = '/api/auth/password/resend';

  static const String resetPassword = '/api/auth/password/reset';

  // ------------------------------------------------------------
  // USER
  // ------------------------------------------------------------

  static const String currentUser = '/api/users/me';
  static const String changePassword = '/api/users/me/password';
  static const String logout = '/api/users/logout';

  // ------------------------------------------------------------
  // GUIDES
  // ------------------------------------------------------------

  static const String guideRegister = '/api/guides/register';
  static const String guideResubmit = '/api/guides/resubmit';
  static const String currentGuide = '/api/guides/me';
  static const String approvedGuides = '/api/guides/approved';

  static const String adminGuides = '/api/admin/guides';

  static String reviewGuide(int guideProfileId) {
    return '/api/admin/guides/$guideProfileId/review';
  }

  // ------------------------------------------------------------
  // HISTORICAL PLACES
  // ------------------------------------------------------------

  static const String historicalPlaces = '/api/places';

  static const String searchHistoricalPlaces = '/api/places/search';

  static const String topTourHistoricalPlaces = '/api/places/trending';

  static String historicalPlaceById(int id) {
    return '/api/places/$id';
  }

  // ------------------------------------------------------------
  // POSTS
  // ------------------------------------------------------------

  static const String posts = '/api/posts';

  static String postById(int id) {
    return '/api/posts/$id';
  }

  static String likePost(int id) {
    return '/api/posts/$id/like';
  }

  static String postComments(int id) {
    return '/api/posts/$id/comments';
  }

  static String likePostComment(int postId, int commentId) {
    return '/api/posts/$postId/comments/$commentId/like';
  }

  // ------------------------------------------------------------
  // POST IMAGE UPLOAD
  // ------------------------------------------------------------

  static const String uploadPostImage = '/api/uploads/post-image';

  static const String uploadPlaceImage = '/api/uploads/place-image';

  // ------------------------------------------------------------
  // TOURS
  // ------------------------------------------------------------

  static const String tours = '/api/tours';

  static String tourById(int id) {
    return '/api/tours/$id';
  }

  static String userTours(int userId) {
    return '/api/tours/user/$userId';
  }

  static String completeTour(int tourId) {
    return '/api/tours/$tourId/complete';
  }

  static String tourPlaceStatus(int tourId, int historicalPlaceId) {
    return '/api/tours/$tourId/places/$historicalPlaceId/status';
  }

  // ------------------------------------------------------------
  // BOOKINGS
  // ------------------------------------------------------------

  static const String myBookings = '/api/bookings/me';

  static const String createDemoBooking = '/api/bookings/demo';

  static String bookingById(int bookingId) {
    return '/api/bookings/$bookingId';
  }

  // ------------------------------------------------------------
  // PAYMENTS
  // ------------------------------------------------------------

  static String payBooking(int bookingId) {
    return '/api/bookings/$bookingId/payments';
  }

  // ------------------------------------------------------------
  // REVIEWS
  // ------------------------------------------------------------

  static const String submitReview = '/api/reviews';

  static const String myReviews = '/api/reviews/me';

  static String guideReviews(int guideProfileId) {
    return '/api/reviews/guide/$guideProfileId';
  }

  static String guideRatingSummary(int guideProfileId) {
    return '/api/reviews/guide/$guideProfileId/summary';
  }
}
