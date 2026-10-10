package com.historia.backend.controller;

import com.historia.backend.dto.ReviewDto;
import com.historia.backend.service.ReviewService;
import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }


    // Submit a review for a paid booking
    @PostMapping
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<ReviewDto.ReviewResponse> submitReview(
            Authentication authentication,
            @Valid @RequestBody ReviewDto.ReviewRequest request
    ) {

        return ResponseEntity.ok(
                reviewService.submitReview(
                        authentication.getName(),
                        request
                )
        );
    }


    // My submitted reviews
    @GetMapping("/me")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<List<ReviewDto.ReviewResponse>> getMyReviews(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                reviewService.getMyReviews(
                        authentication.getName()
                )
        );
    }


    // Public reviews for a guide's profile
    @GetMapping("/guide/{guideProfileId}")
    public ResponseEntity<List<ReviewDto.ReviewResponse>> getGuideReviews(
            @PathVariable Long guideProfileId
    ) {

        return ResponseEntity.ok(
                reviewService.getGuideReviews(guideProfileId)
        );
    }


    // Public rating summary for a guide's profile
    @GetMapping("/guide/{guideProfileId}/summary")
    public ResponseEntity<ReviewDto.GuideRatingSummaryResponse> getGuideRatingSummary(
            @PathVariable Long guideProfileId
    ) {

        return ResponseEntity.ok(
                reviewService.getGuideRatingSummary(guideProfileId)
        );
    }

    // Update my review
    @PutMapping("/{reviewId}")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<ReviewDto.ReviewResponse> updateReview(
            Authentication authentication,
            @PathVariable Long reviewId,
            @Valid @RequestBody ReviewDto.ReviewUpdateRequest request
    ) {

        return ResponseEntity.ok(
                reviewService.updateReview(
                        authentication.getName(),
                        reviewId,
                        request
                )
        );
    }

    // Delete my review
    @DeleteMapping("/{reviewId}")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<Void> deleteReview(
            Authentication authentication,
            @PathVariable Long reviewId
    ) {

        reviewService.deleteReview(
                authentication.getName(),
                reviewId
        );

        return ResponseEntity.noContent().build();
    }
}
