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
    final response = await _apiService.dio.get(
      ApiConfig.historicalPlaces,
    );

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
  Future<List<HistoricalPlaceModel>> searchPlaces(
    String query,
  ) async {
    final trimmedQuery = query.trim();

    // Empty search -> return all places
    if (trimmedQuery.isEmpty) {
      return getAllPlaces();
    }

    final response = await _apiService.dio.get(
      ApiConfig.searchHistoricalPlaces,
      queryParameters: {
        'query': trimmedQuery,
      },
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

    return HistoricalPlaceModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}