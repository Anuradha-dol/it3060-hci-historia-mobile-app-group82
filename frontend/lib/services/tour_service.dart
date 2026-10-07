import '../config/api_config.dart';
import '../models/tour_model.dart';
import 'api_service.dart';

class TourService {
  final ApiService _apiService = ApiService.instance;

  Future<TourModel> createTour({
    required int userId,
    required String title,
    required List<int> historicalPlaceIds,
  }) async {
    final response = await _apiService.dio.post(
      ApiConfig.tours,
      data: {
        'userId': userId,
        'title': title.trim(),
        'tourDate': DateTime.now().toIso8601String().split('T').first,
        'historicalPlaceIds': historicalPlaceIds,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid create tour response.');
    }

    return TourModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TourModel> getTourById(int tourId) async {
    final response = await _apiService.dio.get(ApiConfig.tourById(tourId));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid tour response.');
    }

    return TourModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<TourModel>> getUserTours(int userId) async {
    final response = await _apiService.dio.get(ApiConfig.userTours(userId));

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid tours response.');
    }

    return data
        .map(
          (item) => TourModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<TourModel> updatePlaceStatus({
    required int tourId,
    required int historicalPlaceId,
    required bool completed,
  }) async {
    final response = await _apiService.dio.put(
      ApiConfig.tourPlaceStatus(tourId, historicalPlaceId),
      data: {'completed': completed},
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid tour progress response.');
    }

    return TourModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<TourModel> completeTour(int tourId) async {
    final response = await _apiService.dio.put(ApiConfig.completeTour(tourId));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Invalid complete tour response.');
    }

    return TourModel.fromJson(Map<String, dynamic>.from(data));
  }
}
