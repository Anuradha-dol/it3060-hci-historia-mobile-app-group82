import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/historical_place_model.dart';
import 'api_service.dart';

class HistoricalPlaceService {
  final ApiService _apiService = ApiService.instance;

  /// Get all historical places
  ///
  /// Backend:
  /// GET /api/places
  Future<List<HistoricalPlaceModel>> getAllPlaces() async {
    final response = await _apiService.dio.get(ApiConfig.historicalPlaces);

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid historical places response.');
    }

    return data
        .map(
          (item) => HistoricalPlaceModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// Search historical places by name
  ///
  /// Backend:
  /// GET /api/places/search?query=Sigiriya
  Future<List<HistoricalPlaceModel>> searchPlaces(String query) async {
    final trimmedQuery = query.trim();

    // Empty search -> return all places
    if (trimmedQuery.isEmpty) {
      return getAllPlaces();
    }

    final response = await _apiService.dio.get(
      ApiConfig.searchHistoricalPlaces,
      queryParameters: {'query': trimmedQuery},
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid search response.');
    }

    return data
        .map(
          (item) => HistoricalPlaceModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<HistoricalPlaceModel>> getTopTourPlaces({int limit = 5}) async {
    final response = await _apiService.dio.get(
      ApiConfig.topTourHistoricalPlaces,
      queryParameters: {'limit': limit},
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid top historical places response.');
    }

    return data
        .map(
          (item) => HistoricalPlaceModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  /// Get one historical place using its database ID
  ///
  /// Backend:
  /// GET /api/places/{id}
  Future<HistoricalPlaceModel> getPlaceById(int id) async {
    final response = await _apiService.dio.get(
      ApiConfig.historicalPlaceById(id),
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid historical place response.');
    }

    return HistoricalPlaceModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<String> uploadPlaceImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
    });

    final response = await _apiService.dio.post(
      ApiConfig.uploadPlaceImage,
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

  Future<HistoricalPlaceModel> createPlace({
    required String name,
    required String location,
    required String description,
    required double entranceFee,
    required List<String> imageUrls,
    String subtitle = '',
    String openingHours = '',
  }) async {
    final response = await _apiService.dio.post(
      ApiConfig.historicalPlaces,
      data: {
        'name': name.trim(),
        'subtitle': subtitle.trim(),
        'location': location.trim(),
        'description': description.trim(),
        'rating': 0.0,
        'reviewCount': 0,
        'entranceFee': entranceFee,
        'openingHours': openingHours.trim(),
        'mainImageUrl': imageUrls.isEmpty ? null : imageUrls.first,
        'galleryImages': imageUrls,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid create place response.');
    }

    return HistoricalPlaceModel.fromJson(Map<String, dynamic>.from(data));
  }
}
