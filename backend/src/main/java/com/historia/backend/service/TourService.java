package com.historia.backend.service;

import com.historia.backend.dto.TourCreateRequest;
import com.historia.backend.dto.TourDto;

import java.util.List;

public interface TourService {

    TourDto createTour(TourCreateRequest request);

    TourDto getTourById(Long id);

    List<TourDto> getToursByUserId(Long userId);

    TourDto markPlaceCompleted(
            Long tourId,
            Long historicalPlaceId
    );

    TourDto completeTour(Long tourId);

    void deleteTour(Long id);
}