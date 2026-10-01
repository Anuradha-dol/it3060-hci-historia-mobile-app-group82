package com.historia.backend.service;

import com.historia.backend.entity.HistoricalPlace;

import java.util.List;

public interface HistoricalPlaceService {

    List<HistoricalPlace> getAllPlaces();

    HistoricalPlace getPlaceById(Long id);

    List<HistoricalPlace> searchPlaces(String query);

    HistoricalPlace createPlace(HistoricalPlace historicalPlace);
    HistoricalPlace updatePlace(Long id, HistoricalPlace historicalPlace);
    void deletePlace(Long id);

}