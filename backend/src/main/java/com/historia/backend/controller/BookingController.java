package com.historia.backend.controller;

import com.historia.backend.dto.BookingDto;
import com.historia.backend.service.BookingService;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }


    // Booking summary for the checkout screen
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<BookingDto.BookingCheckoutResponse> getBooking(
            Authentication authentication,
            @PathVariable Long id
    ) {

        return ResponseEntity.ok(
                bookingService.getBookingForCheckout(
                        authentication.getName(),
                        id
                )
        );
    }


    // My bookings
    @GetMapping("/me")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<List<BookingDto.BookingCheckoutResponse>> getMyBookings(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                bookingService.getMyBookings(
                        authentication.getName()
                )
        );
    }


    // Temporary helper until the real booking/scheduling feature exists:
    // creates a sample booking for the logged-in tourist so the checkout,
    // payment and review flows can be tested end-to-end.
    @PostMapping("/demo")
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<BookingDto.BookingCheckoutResponse> createDemoBooking(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                bookingService.createDemoBooking(
                        authentication.getName()
                )
        );
    }
}
