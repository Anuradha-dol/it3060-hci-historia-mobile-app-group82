package com.historia.backend.service.serviceImpl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.historia.backend.dto.ReviewDto;
import com.historia.backend.entity.Booking;
import com.historia.backend.entity.Review;
import com.historia.backend.entity.User;
import com.historia.backend.enums.BookingStatus;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.BookingRepository;
import com.historia.backend.repository.ReviewRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.ReviewService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ReviewServiceImpl(
            ReviewRepository reviewRepository,
            BookingRepository bookingRepository,
            UserRepository userRepository
    ) {
        this.reviewRepository = reviewRepository;
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public ReviewDto.ReviewResponse submitReview(
            String username,
            ReviewDto.ReviewRequest request
    ) {
        // Get tourist
        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new UserException("User not found"));

        // Get booking
        Booking booking = bookingRepository
                .findById(request.bookingId())
                .orElseThrow(() -> new UserException("Booking not found"));

        // Verify booking belongs to this tourist
        if (!booking.getTourist().getId().equals(tourist.getId())) {
            throw new UserException("This booking does not belong to you");
        }

        // Check booking is paid
        if (booking.getStatus() != BookingStatus.PAID) {
            throw new UserException("Only paid bookings can be reviewed");
        }

        // Check review doesn't already exist
        if (reviewRepository.existsByBookingId(booking.getId())) {
            throw new UserException("This booking has already been reviewed");
        }

        // Extract guide info from booking
        Long guideProfileId = booking.getGuideProfile().getId();
        String guideName = booking.getGuideProfile().getDisplayName();

        // Prepare comment
        String comment = request.comment() == null
                ? null
                : request.comment().trim();
        if (comment != null && comment.isBlank()) {
            comment = null;
        }

        // Serialize imageUrls to JSON
        String imageUrlsJson = serializeImageUrls(
                request.imageUrls() == null ? new ArrayList<>() : request.imageUrls()
        );

        // Create review
        Review review = Review.builder()
                .bookingId(booking.getId())
                .touristId(tourist.getId())
                .guideProfileId(guideProfileId)
                .guideName(guideName)
                .navigationRating(request.navigationRating())
                .informationRating(request.informationRating())
                .facilitiesRating(request.facilitiesRating())
                .comment(comment)
                .photoCount(request.photoCount() == null ? 0 : request.photoCount())
                .imageUrlsJson(imageUrlsJson)
                .build();

        reviewRepository.save(review);

        return toResponse(review);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReviewDto.ReviewResponse> getMyReviews(String username) {
        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new UserException("User not found"));

        return reviewRepository
                .findByTouristIdOrderByCreatedAtDesc(tourist.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReviewDto.ReviewResponse> getGuideReviews(Long guideProfileId) {
        return reviewRepository
                .findByGuideProfileIdOrderByCreatedAtDesc(guideProfileId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewDto.GuideRatingSummaryResponse getGuideRatingSummary(Long guideProfileId) {
        List<Review> reviews = reviewRepository.findByGuideProfileId(guideProfileId);

        if (reviews.isEmpty()) {
            return new ReviewDto.GuideRatingSummaryResponse(
                    guideProfileId,
                    0.0,
                    0L
            );
        }

        double averageRating = reviews.stream()
                .mapToDouble(r -> (r.getNavigationRating() + r.getInformationRating() + r.getFacilitiesRating()) / 3.0)
                .average()
                .orElse(0.0);

        return new ReviewDto.GuideRatingSummaryResponse(
                guideProfileId,
                Math.round(averageRating * 10.0) / 10.0,
                reviews.size()
        );
    }

    @Override
    @Transactional
    public ReviewDto.ReviewResponse updateReview(
            String username,
            Long reviewId,
            ReviewDto.ReviewUpdateRequest request
    ) {
        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new UserException("User not found"));

        Review review = reviewRepository
                .findById(reviewId)
                .orElseThrow(() -> new UserException("Review not found"));

        // Verify ownership
        if (!review.getTouristId().equals(tourist.getId())) {
            throw new UserException("You can only update your own reviews");
        }

        // Update ratings if provided
        if (request.navigationRating() != null) {
            review.setNavigationRating(request.navigationRating());
        }
        if (request.informationRating() != null) {
            review.setInformationRating(request.informationRating());
        }
        if (request.facilitiesRating() != null) {
            review.setFacilitiesRating(request.facilitiesRating());
        }

        // Update comment if provided
        if (request.comment() != null) {
            String comment = request.comment().trim();
            review.setComment(comment.isBlank() ? null : comment);
        }

        // Update photo count if provided
        if (request.photoCount() != null) {
            review.setPhotoCount(request.photoCount());
        }

        // Update image URLs if provided
        if (request.imageUrls() != null) {
            String imageUrlsJson = serializeImageUrls(request.imageUrls());
            review.setImageUrlsJson(imageUrlsJson);
        }

        reviewRepository.save(review);

        return toResponse(review);
    }

    @Override
    @Transactional
    public void deleteReview(String username, Long reviewId) {
        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() -> new UserException("User not found"));

        Review review = reviewRepository
                .findById(reviewId)
                .orElseThrow(() -> new UserException("Review not found"));

        // Verify ownership
        if (!review.getTouristId().equals(tourist.getId())) {
            throw new UserException("You can only delete your own reviews");
        }

        reviewRepository.delete(review);
    }

    /**
     * Convert Review entity to ReviewResponse DTO
     */
    private ReviewDto.ReviewResponse toResponse(Review review) {
        List<String> imageUrls = deserializeImageUrls(review.getImageUrlsJson());

        return new ReviewDto.ReviewResponse(
                review.getId(),
                review.getBookingId(),
                review.getGuideProfileId(),
                review.getGuideName(),
                review.getNavigationRating(),
                review.getInformationRating(),
                review.getFacilitiesRating(),
                review.getComment(),
                review.getPhotoCount(),
                imageUrls,
                review.getCreatedAt()
        );
    }

    /**
     * Serialize image URLs list to JSON string
     */
    private String serializeImageUrls(List<String> imageUrls) {
        try {
            if (imageUrls == null || imageUrls.isEmpty()) {
                return "[]";
            }
            return objectMapper.writeValueAsString(imageUrls);
        } catch (Exception e) {
            return "[]";
        }
    }

    /**
     * Deserialize image URLs from JSON string
     */
    private List<String> deserializeImageUrls(String imageUrlsJson) {
        try {
            if (imageUrlsJson == null || imageUrlsJson.trim().isEmpty()) {
                return new ArrayList<>();
            }
            return objectMapper.readValue(
                    imageUrlsJson,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, String.class)
            );
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }
}
