import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/guide_model.dart';
import 'api_service.dart';

class AdminGuideService {
  final Dio _dio = ApiService.instance.dio;

  Future<List<GuideModel>> getGuidesByStatus(String status) async {
    final response = await _dio.get(
      ApiConfig.adminGuides,
      queryParameters: {'status': status},
    );

    final List<dynamic> data = response.data;

    return data
        .map((item) => GuideModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<GuideModel> reviewGuide({
    required int guideProfileId,
    required String status,
    String? adminNote,
  }) async {
    final response = await _dio.put(
      ApiConfig.reviewGuide(guideProfileId),
      data: {'status': status, 'adminNote': adminNote},
    );

    return GuideModel.fromJson(Map<String, dynamic>.from(response.data));
  }
}
