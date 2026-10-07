package com.historia.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "tours")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tour {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // User who created the tour
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Optional tour name/title
    @Column(length = 150)
    private String title;

    // Planned date
    private LocalDate tourDate;

    // Distance can be filled later from frontend / map API
    private Double totalDistanceKm;

    // Estimated duration in minutes
    private Integer estimatedDurationMinutes;

    // PLANNED / ACTIVE / COMPLETED
    @Column(nullable = false, length = 20)
    private String status;

    // Progress percentage
    @Builder.Default
    @Column(nullable = false)
    private Integer progressPercentage = 0;

    // Selected places in the tour
    @OneToMany(
            mappedBy = "tour",
            cascade = CascadeType.ALL,
            orphanRemoval = true
    )
    @OrderBy("placeOrder ASC")
    @Builder.Default
    private List<TourPlace> tourPlaces = new ArrayList<>();

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
            status = "PLANNED";
        }

        if (progressPercentage == null) {
            progressPercentage = 0;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}