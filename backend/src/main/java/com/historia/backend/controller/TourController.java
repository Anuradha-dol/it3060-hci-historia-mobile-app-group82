package com.historia.backend.controller;

import com.historia.backend.dto.TourCreateRequest;
import com.historia.backend.dto.TourDto;
import com.historia.backend.entity.User;
import com.historia.backend.service.TourService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tours")
@PreAuthorize("hasRole('TOURIST')")
public class TourController {

    private final TourService tourService;

    public TourController(
            TourService tourService
    ) {
        this.tourService = tourService;
    }

    // =========================================================
    // CREATE TOUR
    // =========================================================

    @PostMapping
    public ResponseEntity<TourDto> createTour(
            @RequestBody TourCreateRequest request,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.createTour(
                        request,
                        loggedInUser.getId()
                )
        );
    }

    // =========================================================
    // GET TOUR BY ID
    // =========================================================

    @GetMapping("/{id}")
    public ResponseEntity<TourDto> getTourById(
            @PathVariable Long id,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.getTourById(
                        id,
                        loggedInUser.getId()
                )
        );
    }

    // =========================================================
    // GET USER TOURS
    // =========================================================

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TourDto>> getToursByUserId(
            @PathVariable Long userId,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.getToursByUserId(
                        userId,
                        loggedInUser.getId()
                )
        );
    }

    // =========================================================
    // MARK PLACE COMPLETED
    // =========================================================

    @PutMapping(
            "/{tourId}/places/{historicalPlaceId}/complete"
    )
    public ResponseEntity<TourDto> markPlaceCompleted(
            @PathVariable Long tourId,
            @PathVariable Long historicalPlaceId,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.markPlaceCompleted(
                        tourId,
                        historicalPlaceId,
                        loggedInUser.getId()
                )
        );
    }

    // =========================================================
    // COMPLETE TOUR
    // =========================================================

    @PutMapping("/{tourId}/complete")
    public ResponseEntity<TourDto> completeTour(
            @PathVariable Long tourId,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.completeTour(
                        tourId,
                        loggedInUser.getId()
                )
        );
    }

    // =========================================================
    // DELETE TOUR
    // =========================================================

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTour(
            @PathVariable Long id,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        tourService.deleteTour(
                id,
                loggedInUser.getId()
        );

        return ResponseEntity
                .noContent()
                .build();
    }
}