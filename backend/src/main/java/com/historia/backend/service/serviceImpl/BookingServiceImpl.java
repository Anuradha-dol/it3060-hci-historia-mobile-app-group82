package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.BookingDto;
import com.historia.backend.entity.Booking;
import com.historia.backend.entity.GuideProfile;
import com.historia.backend.entity.User;
import com.historia.backend.enums.BookingStatus;
import com.historia.backend.enums.GuideApplicationStatus;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.BookingRepository;
import com.historia.backend.repository.GuideProfileRepository;
import com.historia.backend.repository.ReviewRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.BookingService;
import com.historia.backend.service.NotificationService;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Service
public class BookingServiceImpl implements BookingService {

    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final GuideProfileRepository guideProfileRepository;
    private final ReviewRepository reviewRepository;
    private final NotificationService notificationService;

    public BookingServiceImpl(
            BookingRepository bookingRepository,
            UserRepository userRepository,
            GuideProfileRepository guideProfileRepository,
            ReviewRepository reviewRepository,
            NotificationService notificationService
    ) {
        this.bookingRepository = bookingRepository;
        this.userRepository = userRepository;
        this.guideProfileRepository = guideProfileRepository;
        this.reviewRepository = reviewRepository;
        this.notificationService = notificationService;
    }


    @Override
    @Transactional(readOnly = true)
    public BookingDto.BookingCheckoutResponse getBookingForCheckout(
            String username,
            Long bookingId
    ) {

        User tourist = getTourist(username);

        Booking booking = bookingRepository
                .findByIdAndTourist(bookingId, tourist)
                .orElseThrow(() ->
                        new UserException("Booking not found")
                );

        return toResponse(booking);
    }


    @Override
    @Transactional(readOnly = true)
    public List<BookingDto.BookingCheckoutResponse> getMyBookings(
            String username
    ) {

        User tourist = getTourist(username);

        return bookingRepository
                .findByTouristOrderByCreatedAtDesc(tourist)
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    @Transactional
    public BookingDto.BookingCheckoutResponse createDemoBooking(
            String username
    ) {

        User tourist = getTourist(username);

        GuideProfile guideProfile = guideProfileRepository
                .findByStatus(GuideApplicationStatus.APPROVED)
                .stream()
                .findFirst()
                .orElseThrow(() ->
                        new UserException(
                                "No approved guides are available yet"
                        )
                );

        Booking booking = Booking.builder()
                .tourist(tourist)
                .guideProfile(guideProfile)
                .tourDate(LocalDate.now().plusDays(11))
                .placesCount(4)
                .durationMinutes(75)
                .amount(new BigDecimal("4500.00"))
                .currency("LKR")
                .status(BookingStatus.PENDING)
                .build();

        bookingRepository.save(booking);

        notifyBookingParticipants(
                booking,
                "BOOKING_CREATED",
                "Booking created",
                tourist.getUsername()
                        + " created a booking with "
                        + guideProfile.getDisplayName()
                        + "."
        );

        return toResponse(booking);
    }


    private User getTourist(String username) {
        return userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }

    private BookingDto.BookingCheckoutResponse toResponse(Booking booking) {

        boolean reviewed = reviewRepository.existsByBookingId(booking.getId());

        return new BookingDto.BookingCheckoutResponse(
                booking.getId(),
                booking.getGuideProfile().getId(),
                booking.getGuideProfile().getDisplayName(),
                booking.getTourDate(),
                booking.getPlacesCount(),
                booking.getDurationMinutes(),
                booking.getAmount(),
                booking.getCurrency(),
                booking.getStatus(),
                reviewed
        );
    }

    private void notifyBookingParticipants(
            Booking booking,
            String type,
            String title,
            String message
    ) {

        String referenceId = booking.getId().toString();

        notificationService.notifyUser(
                booking.getTourist(),
                type,
                title,
                message,
                "BOOKING",
                referenceId,
                "/bookings/" + referenceId
        );

        notificationService.notifyUser(
                booking.getGuideProfile().getUser(),
                type,
                title,
                message,
                "BOOKING",
                referenceId,
                "/guide/bookings/" + referenceId
        );
    }
}
