package com.historia.backend.dto;

import com.historia.backend.enums.BookingStatus;

import java.math.BigDecimal;
import java.time.LocalDate;

public class BookingDto {

    // Booking summary used by the checkout screen
    public record BookingCheckoutResponse(

            Long id,

            Long guideProfileId,

            String guideName,

            LocalDate tourDate,

            Integer placesCount,

            Integer durationMinutes,

            BigDecimal amount,

            String currency,

            BookingStatus status,

            boolean reviewed

    ) {
    }
}
