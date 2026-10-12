package com.historia.backend.service;

import com.historia.backend.dto.BookingDto;

import java.util.List;

public interface BookingService {

    BookingDto.BookingCheckoutResponse getBookingForCheckout(
            String username,
            Long bookingId
    );

    List<BookingDto.BookingCheckoutResponse> getMyBookings(
            String username
    );

    /**
     * Creates a sample booking for the logged-in tourist against the first
     * approved guide. Temporary helper used until the real booking /
     * scheduling feature is implemented, so the checkout, payment and
     * review flows can be exercised end-to-end.
     */
    BookingDto.BookingCheckoutResponse createDemoBooking(
            String username
    );
}
