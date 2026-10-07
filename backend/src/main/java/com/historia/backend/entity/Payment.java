package com.historia.backend.entity;

import com.historia.backend.enums.PaymentMethod;
import com.historia.backend.enums.PaymentStatus;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * A single payment attempt against a {@link Booking}.
 * <p>
 * Only a masked card number and the cardholder name are persisted. The full
 * card number, expiry date and CVV are validated in memory and discarded;
 * they are never written to the database or logged.
 */
@Entity
@Table(name = "payments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PaymentMethod method;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PaymentStatus status;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    @Column(nullable = false, length = 8)
    private String currency;

    @Column(length = 24)
    private String maskedCardNumber;

    @Column(length = 100)
    private String cardHolderName;

    @Column(length = 200)
    private String failureReason;

    @Column(nullable = false, unique = true, length = 40)
    private String transactionRef;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
