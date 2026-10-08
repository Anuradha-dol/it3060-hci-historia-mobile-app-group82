import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/review_submission_model.dart';
import '../services/api_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';

/// User Ratings/Reviews screen.
///
/// Lets the tourist rate Navigation, Information and Facilities, optionally
/// attach photos and a comment, then submit the review.
class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final String tourTitle;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    this.tourTitle = 'your tour',
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  static const _maxPhotos = 2;

  final _reviewService = ReviewService.instance;
  final _commentController = TextEditingController();

  int _navigation = 4;
  int _information = 4;
  int _facilities = 4;
  int _photoCount = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addPhoto() {
    if (_photoCount >= _maxPhotos) {
      showAppMessage(context, 'You can add up to $_maxPhotos photos.');
      return;
    }
    setState(() => _photoCount++);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final submission = ReviewSubmission(
      bookingId: widget.bookingId,
      navigationRating: _navigation,
      informationRating: _information,
      facilitiesRating: _facilities,
      comment: _commentController.text.trim(),
      photoCount: _photoCount,
    );

    try {
      await _reviewService.submitReview(submission);
    } on DioException catch (error) {
      if (!mounted) return;

      setState(() => _submitting = false);
      showAppMessage(
        context,
        ApiService.instance.getErrorMessage(error),
        error: true,
      );
      return;
    }

    if (!mounted) return;

    setState(() => _submitting = false);
    showAppMessage(context, 'Thank you for your review!');
    Navigator.of(context).pop(submission);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            HistoriaHeader(
              title: 'Review',
              eyebrow: 'RATE YOUR EXPERIENCE',
              subtitle: 'Tell us how ${widget.tourTitle} went.',
              icon: Icons.star_outline_rounded,
              actions: [
                HistoriaIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Review',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ratingRow(
                          'Navigation',
                          _navigation,
                          (v) => setState(() => _navigation = v),
                        ),
                        const SizedBox(height: 10),
                        _ratingRow(
                          'Information',
                          _information,
                          (v) => setState(() => _information = v),
                        ),
                        const SizedBox(height: 10),
                        _ratingRow(
                          'Facilities',
                          _facilities,
                          (v) => setState(() => _facilities = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Add Photo', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  _PhotoPicker(
                    photoCount: _photoCount,
                    maxPhotos: _maxPhotos,
                    onAdd: _addPhoto,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 3,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Add Your Comment',
                      filled: true,
                      fillColor: AppColors.mint.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AsyncButton(
                    loading: _submitting,
                    label: 'Submit Review',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        HistoriaStarRating(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final int photoCount;
  final int maxPhotos;
  final VoidCallback onAdd;

  const _PhotoPicker({
    required this.photoCount,
    required this.maxPhotos,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.image_outlined,
            color: AppColors.textMuted,
            size: 26,
          ),
        ),
        for (var i = 0; i < maxPhotos; i++) ...[
          const SizedBox(width: 10),
          _slot(filled: i < photoCount),
        ],
      ],
    );
  }

  Widget _slot({required bool filled}) {
    return InkWell(
      onTap: filled ? null : onAdd,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          filled ? Icons.check_circle_outline_rounded : Icons.add,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
