import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import '../config/google_auth_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: GoogleAuthConfig.clientId,
    serverClientId: GoogleAuthConfig.serverClientId,
  );

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;

  bool get loading => _loading;

  String? get error => _error;

  bool get isLoggedIn => _user != null;

  String? get role => _user?.role;

  Future<void> initialize() async {
    final refreshToken = await _storageService.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final response = await _authService.refresh(refreshToken: refreshToken);

        await _saveSession(response);
        notifyListeners();
        return;
      } catch (_) {
        await _storageService.clearAuthData();
      }
    }

    _user = await _storageService.getUser();
    notifyListeners();
  }

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
      _error = ApiService.instance.getErrorMessage(e);

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> googleLogin({String? role}) async {
    _setLoading(true);

    try {
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();

      if (account == null) {
        _error = 'Google Sign-In was cancelled.';
        return false;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        _error = 'Google ID token was not received.';
        return false;
      }

      final response = await _authService.googleLogin(
        idToken: idToken,
        role: role,
      );

      await _saveSession(response);
      _error = null;
      notifyListeners();

      return true;
    } on PlatformException catch (e) {
      debugPrint(
        'Google Sign-In failed: code=${e.code}; '
        'message=${e.message}; details=${e.details}; '
        'androidPackage=${GoogleAuthConfig.androidPackageName}; '
        'serverClientId=${GoogleAuthConfig.serverClientId}',
      );
      _error = _googleSignInMessage(e);
      return false;
    } catch (e) {
      _error = ApiService.instance.getErrorMessage(e);
      if (_error == 'Something went wrong.') {
        _error = e.toString();
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final updatedUser = await _userService.getMyProfile();

      _user = updatedUser;

      await _storageService.saveUser(updatedUser);

      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      await _userService.logout();
    } catch (_) {}

    await _storageService.clearAuthData();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    _user = null;
    _error = null;

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _googleSignInMessage(PlatformException exception) {
    switch (exception.code) {
      case GoogleSignIn.kSignInCanceledError:
        if (_isAccountReauthFailure(exception.message)) {
          return 'Google account re-authentication failed. Check the emulator Google account, Android package/SHA-1, and Web client ID.';
        }
        return 'Google Sign-In was cancelled.';
      default:
        if (_isDeveloperConfigurationError(exception)) {
          return 'Google Sign-In developer config error. Add this Android package and SHA-1 in Google Cloud, then use the matching Web client ID.';
        }
        if (_isAccountReauthFailure(exception.message)) {
          return 'Google account re-authentication failed. Check the emulator Google account, Android package/SHA-1, and Web client ID.';
        }
        return exception.message ?? 'Google Sign-In failed.';
    }
  }

  bool _isDeveloperConfigurationError(PlatformException exception) {
    return exception.code == 'sign_in_failed' &&
        (exception.message?.contains('ApiException: 10') ?? false);
  }

  bool _isAccountReauthFailure(String? message) {
    return message?.contains('Account reauth failed') ?? false;
  }

  Future<void> _saveSession(AuthResponse response) async {
    await _storageService.saveAccessToken(response.accessToken);

    await _storageService.saveRefreshToken(response.refreshToken);

    await _storageService.saveUser(response.user);

    _user = response.user;
  }
}
