package com.historia.backend.dto;

import com.historia.backend.enums.PaymentMethod;
import com.historia.backend.enums.PaymentStatus;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PaymentDto {

    // Pay for a booking. The amount always comes from the booking itself,
    // never from the client, to prevent price tampering.
    public record CheckoutRequest(

            @NotNull(message = "Payment method is required")
            PaymentMethod method,

            // Only required when method == CARD; validated in the service
            // because the requirement is conditional on the method.
            String cardNumber,

            String cardHolderName,

            String expiryDate,

            String cvv

    ) {
    }

    public record PaymentResponse(

            Long id,

            Long bookingId,

            PaymentMethod method,

            PaymentStatus status,

            BigDecimal amount,

            String currency,

            String failureReason,

            String transactionRef,

            LocalDateTime createdAt

    ) {
    }
}
