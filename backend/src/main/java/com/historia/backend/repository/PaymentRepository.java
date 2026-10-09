package com.historia.backend.repository;

import com.historia.backend.entity.Booking;
import com.historia.backend.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findTopByBookingOrderByCreatedAtDesc(Booking booking);
}
