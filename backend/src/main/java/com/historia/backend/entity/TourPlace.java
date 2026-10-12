package com.historia.backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "tour_places")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TourPlace {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tour_id", nullable = false)
    private Tour tour;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "historical_place_id", nullable = false)
    private HistoricalPlace historicalPlace;

    @Column(nullable = false)
    private Integer placeOrder;

    @Builder.Default
    @Column(nullable = false)
    private boolean completed = false;

    private LocalDateTime completedAt;
}
