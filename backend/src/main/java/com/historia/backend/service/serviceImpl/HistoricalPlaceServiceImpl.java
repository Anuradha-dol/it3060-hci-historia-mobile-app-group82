package com.historia.backend.service.serviceImpl;

import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.repository.HistoricalPlaceRepository;
import com.historia.backend.service.HistoricalPlaceService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class HistoricalPlaceServiceImpl implements HistoricalPlaceService {

    private final HistoricalPlaceRepository historicalPlaceRepository;

    public HistoricalPlaceServiceImpl(
            HistoricalPlaceRepository historicalPlaceRepository) {
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    public List<HistoricalPlace> getAllPlaces() {
        return historicalPlaceRepository.findAll();
    }

    @Override
    public HistoricalPlace getPlaceById(Long id) {
        return historicalPlaceRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Historical place not found"));
    }

    @Override
    public List<HistoricalPlace> searchPlaces(String query) {
        return historicalPlaceRepository
                .findByNameContainingIgnoreCase(query);
    }

    @Override
    public HistoricalPlace createPlace(
            HistoricalPlace historicalPlace) {

        return historicalPlaceRepository.save(historicalPlace);
    }

    @Override
    public HistoricalPlace updatePlace(
            Long id,
            HistoricalPlace updatedPlace) {

        HistoricalPlace existingPlace =
                historicalPlaceRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Historical place not found"
                                ));

        existingPlace.setName(updatedPlace.getName());
        existingPlace.setLocation(updatedPlace.getLocation());
        existingPlace.setDescription(updatedPlace.getDescription());
        existingPlace.setRating(updatedPlace.getRating());
        existingPlace.setEntranceFee(updatedPlace.getEntranceFee());
        existingPlace.setOpeningHours(updatedPlace.getOpeningHours());
        existingPlace.setLatitude(updatedPlace.getLatitude());
        existingPlace.setLongitude(updatedPlace.getLongitude());
        existingPlace.setMainImageUrl(updatedPlace.getMainImageUrl());

        return historicalPlaceRepository.save(existingPlace);
    }

    @Override
    public void deletePlace(Long id) {

        HistoricalPlace existingPlace =
                historicalPlaceRepository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Historical place not found"
                                ));

        historicalPlaceRepository.delete(existingPlace);
    }
}