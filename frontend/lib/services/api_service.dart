import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

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
          ),
        );

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
