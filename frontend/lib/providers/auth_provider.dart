import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  // ============================================================
  // GOOGLE SIGN-IN
  // ============================================================
  //
  // IMPORTANT:
  // serverClientId is NOT supported by google_sign_in_web.
  //
  // Therefore:
  // Web     -> serverClientId = null
  // Android -> serverClientId = GoogleAuthConfig.serverClientId
  //
  // This prevents:
  //
  // "serverClientId is not supported on Web."
  //
  // ============================================================

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const [
      'email',
      'profile',
    ],
    clientId: GoogleAuthConfig.clientId,
    serverClientId:
        kIsWeb ? null : GoogleAuthConfig.serverClientId,
  );

  // ============================================================
  // STATE
  // ============================================================

  UserModel? _user;
  bool _loading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  UserModel? get user => _user;

  bool get loading => _loading;

  String? get error => _error;

  bool get isLoggedIn => _user != null;

  String? get role => _user?.role;

  // ============================================================
  // INITIALIZE AUTH SESSION
  // ============================================================

  Future<void> initialize() async {
    try {
      final refreshToken =
          await _storageService.getRefreshToken();

      if (refreshToken != null &&
          refreshToken.isNotEmpty) {
        try {
          final response = await _authService.refresh(
            refreshToken: refreshToken,
          );

          await _saveSession(response);

          notifyListeners();
          return;
        } catch (_) {
          await _storageService.clearAuthData();
        }
      }

      _user = await _storageService.getUser();

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Auth initialization error: $e',
      );

      _user = null;

      notifyListeners();
    }
  }

  // ============================================================
  // NORMAL LOGIN
  // ============================================================

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      await _saveSession(response);

      _error = null;

      notifyListeners();

      return true;
    } catch (e) {
      _error =
          ApiService.instance.getErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<bool> googleLogin({
    String? role,
  }) async {
    _setLoading(true);

    try {
      // Clear any previous Google session first.
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore sign-out errors before login.
      }

      // Open Google account selector.
      final GoogleSignInAccount? account =
          await _googleSignIn.signIn();

      // User closed/cancelled Google Sign-In.
      if (account == null) {
        _error =
            'Google Sign-In was cancelled.';

        return false;
      }

      // Get Google authentication information.
      final GoogleSignInAuthentication authentication =
          await account.authentication;

      final String? idToken =
          authentication.idToken;

      // Backend requires the Google ID token.
      if (idToken == null ||
          idToken.isEmpty) {
        _error =
            'Google ID token was not received.';

        return false;
      }

      // Send Google ID token to Spring Boot backend.
      final response =
          await _authService.googleLogin(
        idToken: idToken,
        role: role,
      );

      // Save access token, refresh token and user.
      await _saveSession(response);

      _error = null;

      notifyListeners();

      return true;
    } on PlatformException catch (e) {
      debugPrint(
        'Google Sign-In failed: '
        'code=${e.code}; '
        'message=${e.message}; '
        'details=${e.details}; '
        'androidPackage='
        '${GoogleAuthConfig.androidPackageName}; '
        'serverClientId='
        '${GoogleAuthConfig.serverClientId}',
      );

      _error =
          _googleSignInMessage(e);

      return false;
    } catch (e) {
      debugPrint(
        'Google Sign-In unexpected error: $e',
      );

      _error =
          ApiService.instance.getErrorMessage(e);

      if (_error ==
          'Something went wrong.') {
        _error = e.toString();
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH USER PROFILE
  // ============================================================

  Future<void> refreshProfile() async {
    try {
      final updatedUser =
          await _userService.getMyProfile();

      _user = updatedUser;

      await _storageService.saveUser(
        updatedUser,
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Profile refresh failed: $e',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _userService.logout();
    } catch (e) {
      debugPrint(
        'Backend logout failed: $e',
      );
    }

    // Remove locally stored authentication information.
    await _storageService.clearAuthData();

    // Sign out from Google as well.
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint(
        'Google Sign-Out failed: $e',
      );
    }

    _user = null;
    _error = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;

    notifyListeners();
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  void _setLoading(bool value) {
    _loading = value;

    notifyListeners();
  }

  // ============================================================
  // GOOGLE SIGN-IN ERROR MESSAGE
  // ============================================================

  String _googleSignInMessage(
    PlatformException exception,
  ) {
    switch (exception.code) {
      case GoogleSignIn.kSignInCanceledError:
        if (_isAccountReauthFailure(
          exception.message,
        )) {
          return 'Google account re-authentication failed. '
              'Check the emulator Google account, '
              'Android package/SHA-1, and Web client ID.';
        }

        return 'Google Sign-In was cancelled.';

      default:
        if (_isDeveloperConfigurationError(
          exception,
        )) {
          return 'Google Sign-In developer config error. '
              'Add this Android package and SHA-1 '
              'in Google Cloud, then use the '
              'matching Web client ID.';
        }

        if (_isAccountReauthFailure(
          exception.message,
        )) {
          return 'Google account re-authentication failed. '
              'Check the emulator Google account, '
              'Android package/SHA-1, and Web client ID.';
        }

        return exception.message ??
            'Google Sign-In failed.';
    }
  }

  // ============================================================
  // CHECK GOOGLE DEVELOPER CONFIG ERROR
  // ============================================================

  bool _isDeveloperConfigurationError(
    PlatformException exception,
  ) {
    return exception.code ==
            'sign_in_failed' &&
        (exception.message?.contains(
              'ApiException: 10',
            ) ??
            false);
  }

  // ============================================================
  // CHECK ACCOUNT RE-AUTH ERROR
  // ============================================================

  bool _isAccountReauthFailure(
    String? message,
  ) {
    return message?.contains(
          'Account reauth failed',
        ) ??
        false;
  }

  // ============================================================
  // SAVE LOGIN SESSION
  // ============================================================

  Future<void> _saveSession(
    AuthResponse response,
  ) async {
    await _storageService.saveAccessToken(
      response.accessToken,
    );

    await _storageService.saveRefreshToken(
      response.refreshToken,
    );

    await _storageService.saveUser(
      response.user,
    );

    _user = response.user;
  }
}