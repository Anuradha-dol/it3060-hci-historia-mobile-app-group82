package com.historia.backend.service;

import com.historia.backend.dto.ReviewDto;

import java.util.List;

public interface ReviewService {

    ReviewDto.ReviewResponse submitReview(
            String username,
            ReviewDto.ReviewRequest request
    );

    List<ReviewDto.ReviewResponse> getMyReviews(
            String username
    );

    List<ReviewDto.ReviewResponse> getGuideReviews(
            Long guideProfileId
    );

    ReviewDto.GuideRatingSummaryResponse getGuideRatingSummary(
            Long guideProfileId
    );
}
