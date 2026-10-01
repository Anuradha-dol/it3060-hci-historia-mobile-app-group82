import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/guide_model.dart';
import '../models/message_response.dart';
import 'api_service.dart';

class AuthService {
  final Dio _dio = ApiService.instance.dio;

  Future<MessageResponse> registerTourist({
    required String username,
    required String email,
    String? phone,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? address,
  }) async {
    final response = await _dio.post(
      ApiConfig.register,
      data: {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'role': 'TOURIST',
      },
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<GuideModel> registerGuide({required Map<String, dynamic> data}) async {
    final response = await _dio.post(ApiConfig.guideRegister, data: data);

    return GuideModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<GuideModel> resubmitGuide({required Map<String, dynamic> data}) async {
    final response = await _dio.post(ApiConfig.guideResubmit, data: data);

    return GuideModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post(
      ApiConfig.verifyEmail,
      data: {'email': email, 'code': code},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> resendOtp({required String email}) async {
    final response = await _dio.post(
      ApiConfig.resendOtp,
      data: {'email': email},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConfig.login,
      data: {'identifier': identifier, 'password': password},
    );

    return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AuthResponse> refresh({required String refreshToken}) async {
    final response = await _dio.post(
      ApiConfig.refresh,
      data: {'refreshToken': refreshToken},
    );

    return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<AuthResponse> googleLogin({
    required String idToken,
    String? role,
  }) async {
    final data = <String, dynamic>{'idToken': idToken};

    if (role != null) {
      data['role'] = role;
    }

    final response = await _dio.post(ApiConfig.googleLogin, data: data);

    return AuthResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> forgotPassword({
    String? username,
    String? email,
    String? phone,
  }) async {
    final response = await _dio.post(
      ApiConfig.forgotPassword,
      data: {'username': username, 'email': email, 'phone': phone},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> verifyForgotPassword({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post(
      ApiConfig.verifyForgotPassword,
      data: {'email': email, 'code': code},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> resendForgotPasswordOtp({
    required String email,
  }) async {
    final response = await _dio.post(
      ApiConfig.resendForgotPasswordOtp,
      data: {'email': email},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _dio.post(
      ApiConfig.resetPassword,
      data: {
        'email': email,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }
}
