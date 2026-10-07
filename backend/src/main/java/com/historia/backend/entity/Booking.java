package com.historia.backend.entity;

import com.historia.backend.enums.BookingStatus;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * A confirmed guide booking that is ready for (or has completed) checkout.
 * <p>
 * The full booking/scheduling workflow (package selection, time slot,
 * meeting location, etc.) is owned by a different module. This entity only
 * carries the fields the payment and review flows need; it can be extended
 * or replaced once that module lands.
 */
@Entity
@Table(name = "bookings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Booking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "tourist_id", nullable = false)
    private User tourist;

    @ManyToOne(optional = false)
    @JoinColumn(name = "guide_profile_id", nullable = false)
    private GuideProfile guideProfile;

    @Column(nullable = false)
    private LocalDate tourDate;

    @Column(nullable = false)
    private Integer placesCount;

    @Column(nullable = false)
    private Integer durationMinutes;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    @Builder.Default
    @Column(nullable = false, length = 8)
    private String currency = "LKR";

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(nullable = false, length = 20)
    private BookingStatus status = BookingStatus.PENDING;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;

        if (status == null) {
            status = BookingStatus.PENDING;
        }

        if (currency == null || currency.isBlank()) {
            currency = "LKR";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
