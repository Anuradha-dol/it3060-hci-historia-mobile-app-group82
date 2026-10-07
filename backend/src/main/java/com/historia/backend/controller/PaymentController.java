package com.historia.backend.controller;

import com.historia.backend.dto.PaymentDto;
import com.historia.backend.service.PaymentService;
import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/bookings/{bookingId}/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }


    // Pay (or retry payment) for a booking
    @PostMapping
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<PaymentDto.PaymentResponse> pay(
            Authentication authentication,
            @PathVariable Long bookingId,
            @Valid @RequestBody PaymentDto.CheckoutRequest request
    ) {

        return ResponseEntity.ok(
                paymentService.pay(
                        authentication.getName(),
                        bookingId,
                        request
                )
        );
    }
}
