import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/message_response.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final Dio _dio = ApiService.instance.dio;

  Future<UserModel> getMyProfile() async {
    final response = await _dio.get(ApiConfig.currentUser);

    return UserModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? address,
  }) async {
    final response = await _dio.put(
      ApiConfig.currentUser,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
      },
    );

    return UserModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _dio.put(
      ApiConfig.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> logout() async {
    final response = await _dio.post(ApiConfig.logout);

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<MessageResponse> deleteAccount({
    required String currentPassword,
  }) async {
    final response = await _dio.delete(
      ApiConfig.currentUser,
      data: {'currentPassword': currentPassword},
    );

    return MessageResponse.fromJson(Map<String, dynamic>.from(response.data));
  }
}
