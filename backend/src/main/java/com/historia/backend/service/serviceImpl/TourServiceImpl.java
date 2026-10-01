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

    // =========================================================
    // CREATE TOUR
    // =========================================================

    @Override
    @Transactional
    public TourDto createTour(
            TourCreateRequest request,
            Long loggedInUserId
    ) {

        // Logged-in user can only use their own user ID
        if (!loggedInUserId.equals(request.getUserId())) {
            throw new RuntimeException(
                    "You can only create tours for your own account"
            );
        }

        User loggedInUser = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Logged in user not found"
                        )
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
                .totalDistanceKm(
                        request.getTotalDistanceKm()
                )
                .estimatedDurationMinutes(
                        request.getEstimatedDurationMinutes()
                )
                .status("PLANNED")
                .progressPercentage(0)
                .tourPlaces(new ArrayList<>())
                .build();

        int order = 1;

        for (Long placeId :
                request.getHistoricalPlaceIds()) {

            HistoricalPlace historicalPlace =
                    historicalPlaceRepository
                            .findById(placeId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Historical place not found: "
                                                    + placeId
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

        Tour savedTour =
                tourRepository.save(tour);

        return convertToDto(savedTour);
    }

    // =========================================================
    // GET TOUR BY ID
    // =========================================================

    @Override
    @Transactional(readOnly = true)
    public TourDto getTourById(
            Long id,
            Long loggedInUserId
    ) {

        Tour tour = getOwnedTour(
                id,
                loggedInUserId
        );

        return convertToDto(tour);
    }

    // =========================================================
    // GET LOGGED USER'S TOURS
    // =========================================================

    @Override
    @Transactional(readOnly = true)
    public List<TourDto> getToursByUserId(
            Long userId,
            Long loggedInUserId
    ) {

        // Cannot request another user's tours
        if (!loggedInUserId.equals(userId)) {

            throw new RuntimeException(
                    "You can only view your own tours"
            );
        }

        return tourRepository
                .findByUser_IdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::convertToDto)
                .toList();
    }

    // =========================================================
    // MARK HISTORICAL PLACE COMPLETED
    // =========================================================

    @Override
    @Transactional
    public TourDto markPlaceCompleted(
            Long tourId,
            Long historicalPlaceId,
            Long loggedInUserId
    ) {

        Tour tour = getOwnedTour(
                tourId,
                loggedInUserId
        );

        TourPlace tourPlace =
                tour.getTourPlaces()
                        .stream()
                        .filter(place ->
                                place.getHistoricalPlace()
                                        .getId()
                                        .equals(
                                                historicalPlaceId
                                        )
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

        Tour updatedTour =
                tourRepository.save(tour);

        return convertToDto(updatedTour);
    }

    // =========================================================
    // COMPLETE FULL TOUR
    // =========================================================

    @Override
    @Transactional
    public TourDto completeTour(
            Long tourId,
            Long loggedInUserId
    ) {

        Tour tour = getOwnedTour(
                tourId,
                loggedInUserId
        );

        for (TourPlace tourPlace :
                tour.getTourPlaces()) {

            if (!tourPlace.isCompleted()) {

                tourPlace.setCompleted(true);

                tourPlace.setCompletedAt(
                        LocalDateTime.now()
                );
            }
        }

        tour.setProgressPercentage(100);
        tour.setStatus("COMPLETED");

        Tour updatedTour =
                tourRepository.save(tour);

        return convertToDto(updatedTour);
    }

    // =========================================================
    // DELETE TOUR
    // =========================================================

    @Override
    @Transactional
    public void deleteTour(
            Long id,
            Long loggedInUserId
    ) {

        Tour tour = getOwnedTour(
                id,
                loggedInUserId
        );

        tourRepository.delete(tour);
    }

    // =========================================================
    // GET TOUR ONLY IF IT BELONGS TO LOGGED USER
    // =========================================================

    private Tour getOwnedTour(
            Long tourId,
            Long loggedInUserId
    ) {

        return tourRepository
                .findByIdAndUser_Id(
                        tourId,
                        loggedInUserId
                )
                .orElseThrow(() ->
                        new RuntimeException(
                                "Tour not found or you are not allowed to access it"
                        )
                );
    }

    // =========================================================
    // UPDATE TOUR PROGRESS
    // =========================================================

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
                        .filter(
                                TourPlace::isCompleted
                        )
                        .count();

        int progress =
                (int) Math.round(
                        (completedPlaces * 100.0)
                                / totalPlaces
                );

        tour.setProgressPercentage(
                progress
        );

        if (progress >= 100) {

            tour.setStatus(
                    "COMPLETED"
            );
        }
    }

    // =========================================================
    // CONVERT TOUR ENTITY TO DTO
    // =========================================================

    private TourDto convertToDto(
            Tour tour
    ) {

        List<TourDto.TourPlaceDto> places =
                tour.getTourPlaces()
                        .stream()
                        .map(tourPlace ->
                                TourDto.TourPlaceDto
                                        .builder()

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
                                                tourPlace
                                                        .getPlaceOrder()
                                        )

                                        .completed(
                                                tourPlace
                                                        .isCompleted()
                                        )

                                        .completedAt(
                                                tourPlace
                                                        .getCompletedAt()
                                        )

                                        .build()
                        )
                        .toList();

        return TourDto.builder()

                .id(
                        tour.getId()
                )

                .userId(
                        tour.getUser()
                                .getId()
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