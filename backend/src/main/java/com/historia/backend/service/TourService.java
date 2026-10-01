package com.historia.backend.service;

import com.historia.backend.dto.TourCreateRequest;
import com.historia.backend.dto.TourDto;

import java.util.List;

public interface TourService {

    TourDto createTour(
            TourCreateRequest request,
            Long loggedInUserId
    );

    TourDto getTourById(
            Long id,
            Long loggedInUserId
    );

    List<TourDto> getToursByUserId(
            Long userId,
            Long loggedInUserId
    );

    TourDto markPlaceCompleted(
            Long tourId,
            Long historicalPlaceId,
            Long loggedInUserId
    );

    TourDto completeTour(
            Long tourId,
            Long loggedInUserId
    );

    void deleteTour(
            Long id,
            Long loggedInUserId
    );
}