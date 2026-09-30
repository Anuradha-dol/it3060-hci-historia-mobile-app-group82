class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8081';

  // Authentication
  static const String register = '/api/auth/register';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String googleLogin = '/api/auth/google';

  // Password recovery
  static const String forgotPassword = '/api/auth/password/forgot';
  static const String verifyForgotPassword = '/api/auth/password/verify';
  static const String resendForgotPasswordOtp = '/api/auth/password/resend';
  static const String resetPassword = '/api/auth/password/reset';

  // User
  static const String currentUser = '/api/users/me';
  static const String changePassword = '/api/users/me/password';
  static const String logout = '/api/users/logout';

  // Guide
  static const String guideRegister = '/api/guides/register';
  static const String guideResubmit = '/api/guides/resubmit';
  static const String currentGuide = '/api/guides/me';
  static const String approvedGuides = '/api/guides/approved';

  // Admin
  static const String adminGuides = '/api/admin/guides';

  static String reviewGuide(int guideProfileId) {
    return '/api/admin/guides/$guideProfileId/review';
  }
}
