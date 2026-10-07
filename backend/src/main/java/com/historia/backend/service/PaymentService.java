package com.historia.backend.service;

import com.historia.backend.dto.PaymentDto;

public interface PaymentService {

    PaymentDto.PaymentResponse pay(
            String username,
            Long bookingId,
            PaymentDto.CheckoutRequest request
    );
}
