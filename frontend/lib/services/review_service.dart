import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/review_model.dart';
import '../models/review_submission_model.dart';
import 'api_service.dart';

/// Handles all review CRUD operations.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final Dio _dio = ApiService.instance.dio;

  /// CREATE: Submit a new review
  Future<Review> submitReview(ReviewSubmission submission) async {
    final response = await _dio.post(
      ApiConfig.submitReview,
      data: {
        'bookingId': submission.bookingId,
        'navigationRating': submission.navigationRating,
        'informationRating': submission.informationRating,
        'facilitiesRating': submission.facilitiesRating,
        'comment': submission.comment,
        'photoCount': submission.photoCount,
      },
    );
    return Review.fromJson(response.data as Map<String, dynamic>);
  }

  /// Upload a review image
  Future<String> uploadReviewImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post(
      ApiConfig.uploadPostImage, // Reuse existing post image endpoint
      data: formData,
    );

    final imageUrl = response.data['imageUrl']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('No image URL received from server');
    }
    return imageUrl;
  }

  /// READ: Get all my submitted reviews
  Future<List<Review>> getMyReviews() async {
    final response = await _dio.get('/api/reviews/me');
    final list = response.data as List<dynamic>;
    return list.map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// READ: Get reviews for a specific guide
  Future<List<Review>> getGuideReviews(int guideProfileId) async {
    final response = await _dio.get('/api/reviews/guide/$guideProfileId');
    final list = response.data as List<dynamic>;
    return list.map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// UPDATE: Modify an existing review
  Future<Review> updateReview(
    int reviewId,
    int navigationRating,
    int informationRating,
    int facilitiesRating,
    String? comment,
    int photoCount, [
    List<String>? imageUrls,
  ]) async {
    final response = await _dio.put(
      '/api/reviews/$reviewId',
      data: {
        'navigationRating': navigationRating,
        'informationRating': informationRating,
        'facilitiesRating': facilitiesRating,
        'comment': comment,
        'photoCount': photoCount,
        if (imageUrls != null) 'imageUrls': imageUrls,
      },
    );
    return Review.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE: Remove a review
  Future<void> deleteReview(int reviewId) async {
    await _dio.delete('/api/reviews/$reviewId');
  }
}
