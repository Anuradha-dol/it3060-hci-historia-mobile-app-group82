import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();
  static const String _retriedAfterRefreshKey = 'retriedAfterRefresh';

  final StorageService _storageService = StorageService();

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _storageService.getAccessToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
            onError: (error, handler) async {
              if (!_shouldRefreshAndRetry(error)) {
                handler.next(error);
                return;
              }

              try {
                final refreshToken = await _storageService.getRefreshToken();

                if (refreshToken == null || refreshToken.isEmpty) {
                  handler.next(error);
                  return;
                }

                final accessToken = await _refreshAccessToken(refreshToken);

                if (accessToken == null || accessToken.isEmpty) {
                  handler.next(error);
                  return;
                }

                final requestOptions = error.requestOptions;
                requestOptions.extra[_retriedAfterRefreshKey] = true;
                requestOptions.headers['Authorization'] = 'Bearer $accessToken';

                final response = await dio.fetch<dynamic>(requestOptions);

                handler.resolve(response);
              } catch (_) {
                await _storageService.clearAuthData();
                handler.next(error);
              }
            },
          ),
        );

  bool _shouldRefreshAndRetry(DioException error) {
    if (error.response?.statusCode != 401) {
      return false;
    }

    if (error.requestOptions.extra[_retriedAfterRefreshKey] == true) {
      return false;
    }

    return !error.requestOptions.path.startsWith('/api/auth/');
  }

  Future<String?> _refreshAccessToken(String refreshToken) async {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await refreshDio.post(
      ApiConfig.refresh,
      data: {'refreshToken': refreshToken},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      return null;
    }

    final accessToken = data['accessToken']?.toString();
    final newRefreshToken = data['refreshToken']?.toString();

    if (accessToken == null ||
        accessToken.isEmpty ||
        newRefreshToken == null ||
        newRefreshToken.isEmpty) {
      return null;
    }

    await _storageService.saveAccessToken(accessToken);
    await _storageService.saveRefreshToken(newRefreshToken);

    return accessToken;
  }

  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      final statusCode = error.response?.statusCode;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message != null) {
          return message.toString();
        }
      }

      if (data is String && data.isNotEmpty) {
        return data;
      }

      if (statusCode == 401 || statusCode == 403) {
        return 'Please log in again and try once more.';
      }

      if (statusCode == 404) {
        return 'This action is not available on the running server.';
      }

      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timed out.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to the server.';
      }
    }

    return 'Something went wrong.';
  }
}
