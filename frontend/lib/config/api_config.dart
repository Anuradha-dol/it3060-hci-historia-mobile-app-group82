import 'package:flutter/foundation.dart';

class ApiConfig {
  // ------------------------------------------------------------
  // BASE URL
  // ------------------------------------------------------------

  static String get baseUrl {
    // Flutter Web / Chrome
    if (kIsWeb) {
      return 'http://localhost:8081';
    }

    // Android Emulator
    return 'http://10.0.2.2:8081';
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

  static const String forgotPassword =
      '/api/auth/password/forgot';

  static const String verifyForgotPassword =
      '/api/auth/password/verify';

  static const String resendForgotPasswordOtp =
      '/api/auth/password/resend';

  static const String resetPassword =
      '/api/auth/password/reset';

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

  static const String searchHistoricalPlaces =
      '/api/places/search';

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

  // ------------------------------------------------------------
  // POST IMAGE UPLOAD
  // ------------------------------------------------------------

  static const String uploadPostImage =
      '/api/uploads/post-image';
}