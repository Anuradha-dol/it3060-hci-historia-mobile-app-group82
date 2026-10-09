import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/review_submission_model.dart';
import 'api_service.dart';

/// Submits a tourist's rating/review for a completed, paid booking.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final Dio _dio = ApiService.instance.dio;

  Future<void> submitReview(ReviewSubmission submission) async {
    await _dio.post(
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
  }
}
