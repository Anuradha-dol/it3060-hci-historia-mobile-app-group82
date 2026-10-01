package com.historia.backend.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@Builder
public class TourDto {

    private Long id;

    private Long userId;

    private String title;

    private LocalDate tourDate;

    private Double totalDistanceKm;

    private Integer estimatedDurationMinutes;

    private String status;

    private Integer progressPercentage;

    private List<TourPlaceDto> places;

    private LocalDateTime createdAt;

    @Getter
    @Setter
    @Builder
    public static class TourPlaceDto {

        private Long tourPlaceId;

        private Long historicalPlaceId;

        private String historicalPlaceName;

        private Integer placeOrder;

        private boolean completed;

        private LocalDateTime completedAt;
    }
}