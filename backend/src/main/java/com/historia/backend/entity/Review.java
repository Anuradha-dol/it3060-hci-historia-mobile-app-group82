package com.historia.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * A tourist's rating/review of a completed ({@link Booking}) guided tour.
 * One review is allowed per booking.
 */
@Entity
@Table(name = "reviews")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(optional = false)
    @JoinColumn(name = "booking_id", nullable = false, unique = true)
    private Booking booking;

    @ManyToOne(optional = false)
    @JoinColumn(name = "tourist_id", nullable = false)
    private User tourist;

    @ManyToOne(optional = false)
    @JoinColumn(name = "guide_profile_id", nullable = false)
    private GuideProfile guideProfile;

    @Column(nullable = false)
    private Integer navigationRating;

    @Column(nullable = false)
    private Integer informationRating;

    @Column(nullable = false)
    private Integer facilitiesRating;

    @Column(length = 1000)
    private String comment;

    @Builder.Default
    @Column(nullable = false)
    private Integer photoCount = 0;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();

        if (photoCount == null) {
            photoCount = 0;
        }
    }
}
