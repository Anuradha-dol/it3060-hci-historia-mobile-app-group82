import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class PostService {
  final ApiService _apiService = ApiService.instance;

  // ------------------------------------------------------------
  // UPLOAD POST IMAGE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // CREATE POST
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> createPost({
    required int userId,
    required int historicalPlaceId,
    required String caption,
    required List<String> imageUrls,
  }) async {
    final response = await _apiService.dio.post(
      ApiConfig.posts,
      data: {
        'userId': userId,
        'historicalPlaceId': historicalPlaceId,
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

  // ------------------------------------------------------------
  // GET ALL POSTS
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllPosts() async {
    final response = await _apiService.dio.get(ApiConfig.posts);

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid posts response.');
    }

    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // ------------------------------------------------------------
  // GET POST BY ID
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> getPostById(int id) async {
    final response = await _apiService.dio.get(ApiConfig.postById(id));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid post response.');
    }

    return Map<String, dynamic>.from(data);
  }

  // ------------------------------------------------------------
  // LIKE POST
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> likePost(int id) async {
    final response = await _apiService.dio.put(ApiConfig.likePost(id));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid like post response.');
    }

    return Map<String, dynamic>.from(data);
  }

  // ------------------------------------------------------------
  // DELETE POST
  // ------------------------------------------------------------

  Future<void> deletePost(int id) async {
    await _apiService.dio.delete(ApiConfig.postById(id));
  }
}
