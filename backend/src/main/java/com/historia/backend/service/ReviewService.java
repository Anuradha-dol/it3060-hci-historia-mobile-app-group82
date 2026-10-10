package com.historia.backend.service;

import com.historia.backend.dto.ReviewDto;

import java.util.List;

public interface ReviewService {

    // CREATE
    ReviewDto.ReviewResponse submitReview(
            String username,
            ReviewDto.ReviewRequest request
    );

    // READ
    List<ReviewDto.ReviewResponse> getMyReviews(
            String username
    );

    List<ReviewDto.ReviewResponse> getGuideReviews(
            Long guideProfileId
    );

    ReviewDto.GuideRatingSummaryResponse getGuideRatingSummary(
            Long guideProfileId
    );

    // UPDATE
    ReviewDto.ReviewResponse updateReview(
            String username,
            Long reviewId,
            ReviewDto.ReviewUpdateRequest request
    );

    // DELETE
    void deleteReview(
            String username,
            Long reviewId
    );
}
