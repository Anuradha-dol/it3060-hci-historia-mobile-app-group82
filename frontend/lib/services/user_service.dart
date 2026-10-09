import 'dart:typed_data';

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
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    final data = <String, dynamic>{};

    if (firstName != null) {
      data['firstName'] = firstName;
    }

    if (lastName != null) {
      data['lastName'] = lastName;
    }

    if (phone != null) {
      data['phone'] = phone;
    }

    if (address != null) {
      data['address'] = address;
    }

    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }

    if (coverImageUrl != null) {
      data['coverImageUrl'] = coverImageUrl;
    }

    final response = await _dio.put(ApiConfig.currentUser, data: data);

    return UserModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<String> uploadProfileImage({
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return _uploadProfileMedia(
      endpoint: ApiConfig.uploadProfileImage,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  Future<String> uploadCoverImage({
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return _uploadProfileMedia(
      endpoint: ApiConfig.uploadCoverImage,
      imageBytes: imageBytes,
      fileName: fileName,
    );
  }

  Future<String> _uploadProfileMedia({
    required String endpoint,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });

    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid image upload response.');
    }

    final imageUrl = data['imageUrl']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('Image URL was not returned by the server.');
    }

    return imageUrl;
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
