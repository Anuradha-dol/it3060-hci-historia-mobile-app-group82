import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/review_submission_model.dart';
import '../services/api_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/form_helpers.dart';
import '../widgets/historia_components.dart';
import 'my_reviews_screen.dart';

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
    
    // Navigate to MyReviewsScreen to show the submitted review
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
    );
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
              child: Stack(
                children: [
                  // Background Image - Full Screen
                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(child: Container(color: AppColors.background)),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/home_banner.jpg'),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Help Us Improve Your Experience',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 220),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Intro Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.mint, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'How was your tour?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rate your experience to help us improve.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Rating Section Title
                      const Text(
                        'Rate Your Experience',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Rating Cards
                      _RatingCard(
                        icon: Icons.map_outlined,
                        title: 'Navigation',
                        subtitle: 'How clear were the directions?',
                        value: _navigation,
                        onChanged: (v) => setState(() => _navigation = v),
                      ),
                      const SizedBox(height: 12),
                      _RatingCard(
                        icon: Icons.info_outline_rounded,
                        title: 'Information Quality',
                        subtitle: 'How informative was the guide?',
                        value: _information,
                        onChanged: (v) => setState(() => _information = v),
                      ),
                      const SizedBox(height: 12),
                      _RatingCard(
                        icon: Icons.location_city_outlined,
                        title: 'Facilities',
                        subtitle: 'Cleanliness and maintenance',
                        value: _facilities,
                        onChanged: (v) => setState(() => _facilities = v),
                      ),
                      const SizedBox(height: 28),

                      // Photos Section
                      const Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share up to $_maxPhotos photos from your experience',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PhotoPicker(
                        photoCount: _photoCount,
                        maxPhotos: _maxPhotos,
                        onAdd: _addPhoto,
                      ),
                      const SizedBox(height: 28),

                      // Comment Section
                      const Text(
                        'Share Your Thoughts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us what you loved (or didn\'t)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your experience here...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.8,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Submit Button
                      AsyncButton(
                        loading: _submitting,
                        label: 'Submit Review',
                        icon: Icons.check_circle_rounded,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
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

class _RatingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  const _RatingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rating: $value/5',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              HistoriaStarRating(value: value, onChanged: onChanged),
            ],
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add Photo Button
            Expanded(
              child: GestureDetector(
                onTap: photoCount >= maxPhotos ? null : onAdd,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: photoCount >= maxPhotos
                        ? AppColors.border.withValues(alpha: 0.3)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: photoCount >= maxPhotos
                          ? AppColors.border
                          : AppColors.primary,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 32,
                        color: photoCount >= maxPhotos
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photoCount >= maxPhotos
                            ? 'Max photos added'
                            : 'Add Photo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: photoCount >= maxPhotos
                              ? AppColors.textMuted
                              : AppColors.primary,
                        ),
                      ),
                      Text(
                        '$photoCount/$maxPhotos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Photo Indicators
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < maxPhotos; i++)
                  _PhotoIndicator(
                    filled: i < photoCount,
                    index: i,
                  ),
              ],
            ),
          ],
        ),
        if (photoCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$photoCount of $maxPhotos photos added',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoIndicator extends StatelessWidget {
  final bool filled;
  final int index;

  const _PhotoIndicator({
    required this.filled,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : AppColors.border,
      ),
      child: filled
          ? const Icon(Icons.check, size: 8, color: Colors.white)
          : null,
    );
  }
}
