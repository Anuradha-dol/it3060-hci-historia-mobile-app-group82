package com.historia.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * A tourist's rating/review of a completed tour.
 * Stores ONLY review data - no complex relationships to avoid lazy-loading issues.
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

    @Column(nullable = false)
    private Long bookingId;

    @Column(nullable = false)
    private Long touristId;

    @Column(nullable = false)
    private Long guideProfileId;

    @Column(nullable = false, length = 100)
    private String guideName;

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

    @Column(columnDefinition = "TEXT")
    private String imageUrlsJson;  // Stores JSON array: ["url1", "url2"]

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
