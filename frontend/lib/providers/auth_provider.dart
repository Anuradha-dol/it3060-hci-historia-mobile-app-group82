import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

enum _StartupAuthResult { authenticated, unauthenticated, transientFailure }

enum _StoredJwtStatus { missing, valid, expired, invalid }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb ? GoogleAuthConfig.clientId : null,
    serverClientId: kIsWeb ? null : GoogleAuthConfig.serverClientId,
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
    _user = null;
    _error = null;

    try {
      final accessToken = _cleanToken(await _storageService.getAccessToken());
      final refreshToken = _cleanToken(await _storageService.getRefreshToken());

      final accessStatus = _getJwtStatus(accessToken, expectedType: 'ACCESS');

      if (accessStatus == _StoredJwtStatus.valid) {
        final result = await _restoreSessionFromAccessToken();

        if (result == _StartupAuthResult.authenticated ||
            result == _StartupAuthResult.transientFailure) {
          return;
        }

        await _clearInvalidStartupSession();
        return;
      }

      if (accessStatus == _StoredJwtStatus.invalid) {
        await _clearInvalidStartupSession();
        return;
      }

      final refreshStatus = _getJwtStatus(
        refreshToken,
        expectedType: 'REFRESH',
      );

      if (refreshStatus == _StoredJwtStatus.valid && refreshToken != null) {
        final result = await _refreshStoredSession(refreshToken);

        if (result == _StartupAuthResult.authenticated ||
            result == _StartupAuthResult.transientFailure) {
          return;
        }
      }

      await _clearInvalidStartupSession();
    } catch (e) {
      debugPrint('Auth initialization error: $e');

      await _clearInvalidStartupSession();
    } finally {
      notifyListeners();
    }
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
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        _error = 'Google Sign-In was cancelled.';

        return false;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;

      final String? idToken = authentication.idToken;

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
        'Google Sign-In failed: '
        'code=${e.code}; '
        'message=${e.message}; '
        'details=${e.details}; '
        'androidPackage='
        '${GoogleAuthConfig.androidPackageName}; '
        'serverClientId='
        '${GoogleAuthConfig.serverClientId}',
      );

      _error = _googleSignInMessage(e);

      return false;
    } catch (e) {
      debugPrint('Google Sign-In unexpected error: $e');

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
    } catch (e) {
      debugPrint('Profile refresh failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _userService.logout();
    } catch (e) {
      debugPrint('Backend logout failed: $e');
    }

    await _storageService.clearAuthData();

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }

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

  Future<_StartupAuthResult> _restoreSessionFromAccessToken() async {
    try {
      final user = await _userService.getMyProfile();

      _user = user;
      _error = null;

      await _storageService.saveUser(user);

      return _StartupAuthResult.authenticated;
    } on DioException catch (error) {
      if (_isTransientStartupAuthError(error)) {
        debugPrint(
          'Startup session validation skipped: '
          '${ApiService.instance.getErrorMessage(error)}',
        );

        _user = null;
        _error = null;

        return _StartupAuthResult.transientFailure;
      }

      return _StartupAuthResult.unauthenticated;
    } catch (e) {
      debugPrint('Stored session validation failed: $e');

      return _StartupAuthResult.unauthenticated;
    }
  }

  Future<_StartupAuthResult> _refreshStoredSession(String refreshToken) async {
    try {
      final response = await _authService.refresh(refreshToken: refreshToken);

      await _saveSession(response);

      _error = null;

      return _StartupAuthResult.authenticated;
    } on DioException catch (error) {
      if (_isTransientStartupAuthError(error)) {
        debugPrint(
          'Startup token refresh skipped: '
          '${ApiService.instance.getErrorMessage(error)}',
        );

        _user = null;
        _error = null;

        return _StartupAuthResult.transientFailure;
      }

      return _StartupAuthResult.unauthenticated;
    } catch (e) {
      debugPrint('Stored session refresh failed: $e');

      return _StartupAuthResult.unauthenticated;
    }
  }

  Future<void> _clearInvalidStartupSession() async {
    await _storageService.clearAuthData();

    _user = null;
    _error = null;
  }

  bool _isTransientStartupAuthError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode ?? 0) >= 500;
  }

  String? _cleanToken(String? token) {
    final value = token?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  _StoredJwtStatus _getJwtStatus(
    String? token, {
    required String expectedType,
  }) {
    if (token == null) {
      return _StoredJwtStatus.missing;
    }

    final payload = _decodeJwtPayload(token);

    if (payload == null || payload['type'] != expectedType) {
      return _StoredJwtStatus.invalid;
    }

    final expiration = _readJwtExpiration(payload['exp']);

    if (expiration == null) {
      return _StoredJwtStatus.invalid;
    }

    if (!expiration.isAfter(DateTime.now().toUtc())) {
      return _StoredJwtStatus.expired;
    }

    return _StoredJwtStatus.valid;
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');

    if (parts.length != 3) {
      return null;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  DateTime? _readJwtExpiration(dynamic value) {
    final seconds = switch (value) {
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };

    if (seconds == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  String _googleSignInMessage(PlatformException exception) {
    switch (exception.code) {
      case GoogleSignIn.kSignInCanceledError:
        if (_isAccountReauthFailure(exception.message)) {
          return 'Google account re-authentication failed. '
              'Check the emulator Google account, '
              'Android package/SHA-1, and Web client ID.';
        }

        return 'Google Sign-In was cancelled.';

      default:
        if (_isDeveloperConfigurationError(exception)) {
          return 'Google Sign-In developer config error. '
              'Add this Android package and SHA-1 '
              'in Google Cloud, then use the '
              'matching Web client ID.';
        }

        if (_isAccountReauthFailure(exception.message)) {
          return 'Google account re-authentication failed. '
              'Check the emulator Google account, '
              'Android package/SHA-1, and Web client ID.';
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
