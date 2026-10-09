import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class PostService {
  final ApiService _apiService = ApiService.instance;

  Future<String> uploadPostImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });

    final response = await _apiService.dio.post(
      ApiConfig.uploadPostImage,
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

  Future<Map<String, dynamic>> createPost({
    required int userId,
    int? historicalPlaceId,
    String? customPlaceName,
    required String caption,
    required List<String> imageUrls,
  }) async {
    final response = await _apiService.dio.post(
      ApiConfig.posts,
      data: {
        'userId': userId,
        'historicalPlaceId': historicalPlaceId,
        'customPlaceName': customPlaceName?.trim(),
        'caption': caption.trim(),
        'imageUrls': imageUrls,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid create post response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllPosts() async {
    final response = await _apiService.dio.get(ApiConfig.posts);

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid posts response.');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> getPostById(int id) async {
    final response = await _apiService.dio.get(ApiConfig.postById(id));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid post response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> likePost(int id) async {
    final response = await _apiService.dio.put(ApiConfig.likePost(id));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid like post response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final response = await _apiService.dio.get(ApiConfig.postComments(postId));

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid comments response.');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> addComment({
    required int postId,
    required String commentText,
  }) async {
    final response = await _apiService.dio.post(
      ApiConfig.postComments(postId),
      data: {'commentText': commentText.trim()},
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid add comment response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> likeComment({
    required int postId,
    required int commentId,
  }) async {
    final response = await _apiService.dio.put(
      ApiConfig.likePostComment(postId, commentId),
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid like comment response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<void> deletePost(int id) async {
    await _apiService.dio.delete(ApiConfig.postById(id));
  }
}
