package com.historia.backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
public class TourCreateRequest {

    private Long userId;

    private String title;

    private LocalDate tourDate;

    private List<Long> historicalPlaceIds;

    private Double totalDistanceKm;

    private Integer estimatedDurationMinutes;
}