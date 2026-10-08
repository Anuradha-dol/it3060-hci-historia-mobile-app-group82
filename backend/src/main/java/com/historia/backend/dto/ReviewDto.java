package com.historia.backend.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class ReviewDto {

    // Submit a review for a paid booking
    public record ReviewRequest(

            @NotNull(message = "Booking is required")
            Long bookingId,

            @NotNull(message = "Navigation rating is required")
            @Min(value = 1, message = "Rating must be between 1 and 5")
            @Max(value = 5, message = "Rating must be between 1 and 5")
            Integer navigationRating,

            @NotNull(message = "Information rating is required")
            @Min(value = 1, message = "Rating must be between 1 and 5")
            @Max(value = 5, message = "Rating must be between 1 and 5")
            Integer informationRating,

            @NotNull(message = "Facilities rating is required")
            @Min(value = 1, message = "Rating must be between 1 and 5")
            @Max(value = 5, message = "Rating must be between 1 and 5")
            Integer facilitiesRating,

            @Size(max = 1000, message = "Comment is too long")
            String comment,

            @Min(value = 0, message = "Photo count cannot be negative")
            @Max(value = 2, message = "Up to 2 photos are allowed")
            Integer photoCount

    ) {
    }

    public record ReviewResponse(

            Long id,

            Long bookingId,

            Long guideProfileId,

            String guideName,

            Integer navigationRating,

            Integer informationRating,

            Integer facilitiesRating,

            String comment,

            Integer photoCount,

            LocalDateTime createdAt

    ) {
    }

    public record GuideRatingSummaryResponse(

            Long guideProfileId,

            double averageRating,

            long totalReviews

    ) {
    }
}
