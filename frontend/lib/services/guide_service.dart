import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/guide_model.dart';
import 'api_service.dart';

class GuideService {
  final Dio _dio = ApiService.instance.dio;

  Future<GuideModel> getMyGuideProfile() async {
    final response = await _dio.get(ApiConfig.currentGuide);

    return GuideModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<GuideModel> updateMyGuideProfile({
    required String displayName,
    required String primaryServiceArea,
    required List<String> serviceAreas,
    required List<String> languages,
    required int yearsExperience,
    String? headline,
    String? bio,
    required List<String> specialties,
  }) async {
    final response = await _dio.put(
      ApiConfig.currentGuide,
      data: {
        'displayName': displayName,
        'primaryServiceArea': primaryServiceArea,
        'serviceAreas': serviceAreas,
        'languages': languages,
        'yearsExperience': yearsExperience,
        'headline': headline,
        'bio': bio,
        'specialties': specialties,
      },
    );

    return GuideModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<List<GuideModel>> getApprovedGuides({String? area}) async {
    final response = await _dio.get(
      ApiConfig.approvedGuides,
      queryParameters: {if (area != null && area.isNotEmpty) 'area': area},
    );

    final List<dynamic> data = response.data;

    return data
        .map((item) => GuideModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
