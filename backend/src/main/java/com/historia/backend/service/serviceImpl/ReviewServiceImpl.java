package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.ReviewDto;
import com.historia.backend.entity.Booking;
import com.historia.backend.entity.GuideProfile;
import com.historia.backend.entity.Review;
import com.historia.backend.entity.User;
import com.historia.backend.enums.BookingStatus;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.BookingRepository;
import com.historia.backend.repository.GuideProfileRepository;
import com.historia.backend.repository.ReviewRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.ReviewService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final GuideProfileRepository guideProfileRepository;

    public ReviewServiceImpl(
            ReviewRepository reviewRepository,
            BookingRepository bookingRepository,
            UserRepository userRepository,
            GuideProfileRepository guideProfileRepository
    ) {
        this.reviewRepository = reviewRepository;
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
        this.guideProfileRepository = guideProfileRepository;
    }


    @Override
    @Transactional
    public ReviewDto.ReviewResponse submitReview(
            String username,
            ReviewDto.ReviewRequest request
    ) {

        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );

        Booking booking = bookingRepository
                .findByIdAndTourist(request.bookingId(), tourist)
                .orElseThrow(() ->
                        new UserException("Booking not found")
                );

        if (booking.getStatus() != BookingStatus.PAID) {
            throw new UserException(
                    "Only paid bookings can be reviewed"
            );
        }

        if (reviewRepository.existsByBooking(booking)) {
            throw new UserException(
                    "This booking has already been reviewed"
            );
        }

        String comment = request.comment() == null
                ? null
                : request.comment().trim();

        Review review = Review.builder()
                .booking(booking)
                .tourist(tourist)
                .guideProfile(booking.getGuideProfile())
                .navigationRating(request.navigationRating())
                .informationRating(request.informationRating())
                .facilitiesRating(request.facilitiesRating())
                .comment(comment == null || comment.isBlank() ? null : comment)
                .photoCount(request.photoCount() == null ? 0 : request.photoCount())
                .build();

        reviewRepository.save(review);

        return toResponse(review);
    }


    @Override
    @Transactional(readOnly = true)
    public List<ReviewDto.ReviewResponse> getMyReviews(String username) {

        User tourist = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );

        return reviewRepository
                .findByTouristOrderByCreatedAtDesc(tourist)
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    @Transactional(readOnly = true)
    public List<ReviewDto.ReviewResponse> getGuideReviews(
            Long guideProfileId
    ) {

        GuideProfile guideProfile = getGuideProfile(guideProfileId);

        return reviewRepository
                .findByGuideProfileOrderByCreatedAtDesc(guideProfile)
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    @Transactional(readOnly = true)
    public ReviewDto.GuideRatingSummaryResponse getGuideRatingSummary(
            Long guideProfileId
    ) {

        GuideProfile guideProfile = getGuideProfile(guideProfileId);

        List<Review> reviews = reviewRepository
                .findByGuideProfileOrderByCreatedAtDesc(guideProfile);

        if (reviews.isEmpty()) {
            return new ReviewDto.GuideRatingSummaryResponse(
                    guideProfileId,
                    0.0,
                    0
            );
        }

        double total = reviews.stream()
                .mapToInt(review ->
                        review.getNavigationRating()
                                + review.getInformationRating()
                                + review.getFacilitiesRating()
                )
                .sum();

        double average = total / (reviews.size() * 3.0);

        return new ReviewDto.GuideRatingSummaryResponse(
                guideProfileId,
                Math.round(average * 10.0) / 10.0,
                reviews.size()
        );
    }


    private GuideProfile getGuideProfile(Long guideProfileId) {
        return guideProfileRepository
                .findById(guideProfileId)
                .orElseThrow(() ->
                        new UserException("Guide not found")
                );
    }

    private ReviewDto.ReviewResponse toResponse(Review review) {
        return new ReviewDto.ReviewResponse(
                review.getId(),
                review.getBooking().getId(),
                review.getGuideProfile().getId(),
                review.getGuideProfile().getDisplayName(),
                review.getNavigationRating(),
                review.getInformationRating(),
                review.getFacilitiesRating(),
                review.getComment(),
                review.getPhotoCount(),
                review.getCreatedAt()
        );
    }
}
