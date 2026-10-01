package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.TourCreateRequest;
import com.historia.backend.dto.TourDto;
import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.entity.Tour;
import com.historia.backend.entity.TourPlace;
import com.historia.backend.entity.User;
import com.historia.backend.repository.HistoricalPlaceRepository;
import com.historia.backend.repository.TourRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.TourService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class TourServiceImpl implements TourService {

    private final TourRepository tourRepository;
    private final UserRepository userRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;

    public TourServiceImpl(
            TourRepository tourRepository,
            UserRepository userRepository,
            HistoricalPlaceRepository historicalPlaceRepository
    ) {
        this.tourRepository = tourRepository;
        this.userRepository = userRepository;
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    @Transactional
    public TourDto createTour(
            TourCreateRequest request,
            Long loggedInUserId
    ) {

        // User can only use their own user ID
        if (!loggedInUserId.equals(request.getUserId())) {
            throw new RuntimeException(
                    "You can only create tours for your own account"
            );
        }

        User loggedInUser = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException("Logged in user not found")
                );

        if (request.getHistoricalPlaceIds() == null
                || request.getHistoricalPlaceIds().isEmpty()) {

            throw new RuntimeException(
                    "At least one historical place is required"
            );
        }

        Tour tour = Tour.builder()
                .user(loggedInUser)
                .title(request.getTitle())
                .tourDate(request.getTourDate())
                .totalDistanceKm(request.getTotalDistanceKm())
                .estimatedDurationMinutes(
                        request.getEstimatedDurationMinutes()
                )
                .status("PLANNED")
                .progressPercentage(0)
                .tourPlaces(new ArrayList<>())
                .build();

        int order = 1;

        for (Long placeId : request.getHistoricalPlaceIds()) {

            HistoricalPlace historicalPlace =
                    historicalPlaceRepository
                            .findById(placeId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Historical place not found: " + placeId
                                    )
                            );

            TourPlace tourPlace = TourPlace.builder()
                    .tour(tour)
                    .historicalPlace(historicalPlace)
                    .placeOrder(order++)
                    .completed(false)
                    .build();

            tour.getTourPlaces().add(tourPlace);
        }

        Tour savedTour = tourRepository.save(tour);

        return convertToDto(savedTour);
    }

    @Override
    @Transactional(readOnly = true)
    public TourDto getTourById(Long id) {

        Tour tour = tourRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Tour not found")
                );

        return convertToDto(tour);
    }

    @Override
    @Transactional(readOnly = true)
    public List<TourDto> getToursByUserId(Long userId) {

        return tourRepository
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::convertToDto)
                .toList();
    }

    @Override
    @Transactional
    public TourDto markPlaceCompleted(
            Long tourId,
            Long historicalPlaceId
    ) {

        Tour tour = tourRepository.findById(tourId)
                .orElseThrow(() ->
                        new RuntimeException("Tour not found")
                );

        TourPlace tourPlace = tour.getTourPlaces()
                .stream()
                .filter(place ->
                        place.getHistoricalPlace()
                                .getId()
                                .equals(historicalPlaceId)
                )
                .findFirst()
                .orElseThrow(() ->
                        new RuntimeException(
                                "Historical place is not in this tour"
                        )
                );

        if (!tourPlace.isCompleted()) {

            tourPlace.setCompleted(true);
            tourPlace.setCompletedAt(
                    LocalDateTime.now()
            );
        }

        tour.setStatus("ACTIVE");

        updateProgress(tour);

        Tour updatedTour = tourRepository.save(tour);

        return convertToDto(updatedTour);
    }

    @Override
    @Transactional
    public TourDto completeTour(Long tourId) {

        Tour tour = tourRepository.findById(tourId)
                .orElseThrow(() ->
                        new RuntimeException("Tour not found")
                );

        for (TourPlace tourPlace : tour.getTourPlaces()) {

            if (!tourPlace.isCompleted()) {

                tourPlace.setCompleted(true);
                tourPlace.setCompletedAt(
                        LocalDateTime.now()
                );
            }
        }

        tour.setProgressPercentage(100);
        tour.setStatus("COMPLETED");

        Tour updatedTour = tourRepository.save(tour);

        return convertToDto(updatedTour);
    }

    @Override
    @Transactional
    public void deleteTour(Long id) {

        Tour tour = tourRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Tour not found")
                );

        tourRepository.delete(tour);
    }

    private void updateProgress(Tour tour) {

        int totalPlaces =
                tour.getTourPlaces().size();

        if (totalPlaces == 0) {
            tour.setProgressPercentage(0);
            return;
        }

        long completedPlaces =
                tour.getTourPlaces()
                        .stream()
                        .filter(TourPlace::isCompleted)
                        .count();

        int progress =
                (int) Math.round(
                        (completedPlaces * 100.0)
                                / totalPlaces
                );

        tour.setProgressPercentage(progress);

        if (progress >= 100) {
            tour.setStatus("COMPLETED");
        }
    }

    private TourDto convertToDto(Tour tour) {

        List<TourDto.TourPlaceDto> places =
                tour.getTourPlaces()
                        .stream()
                        .map(tourPlace ->
                                TourDto.TourPlaceDto.builder()
                                        .tourPlaceId(
                                                tourPlace.getId()
                                        )
                                        .historicalPlaceId(
                                                tourPlace
                                                        .getHistoricalPlace()
                                                        .getId()
                                        )
                                        .historicalPlaceName(
                                                tourPlace
                                                        .getHistoricalPlace()
                                                        .getName()
                                        )
                                        .placeOrder(
                                                tourPlace.getPlaceOrder()
                                        )
                                        .completed(
                                                tourPlace.isCompleted()
                                        )
                                        .completedAt(
                                                tourPlace.getCompletedAt()
                                        )
                                        .build()
                        )
                        .toList();

        return TourDto.builder()
                .id(tour.getId())
                .userId(
                        tour.getUser().getId()
                )
                .title(
                        tour.getTitle()
                )
                .tourDate(
                        tour.getTourDate()
                )
                .totalDistanceKm(
                        tour.getTotalDistanceKm()
                )
                .estimatedDurationMinutes(
                        tour.getEstimatedDurationMinutes()
                )
                .status(
                        tour.getStatus()
                )
                .progressPercentage(
                        tour.getProgressPercentage()
                )
                .places(
                        new ArrayList<>(places)
                )
                .createdAt(
                        tour.getCreatedAt()
                )
                .build();
    }
}