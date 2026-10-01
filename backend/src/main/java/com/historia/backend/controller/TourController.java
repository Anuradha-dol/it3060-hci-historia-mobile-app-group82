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
public class TourController {

    private final TourService tourService;

    public TourController(TourService tourService) {
        this.tourService = tourService;
    }
    @PostMapping
    @PreAuthorize("hasRole('TOURIST')")
    public ResponseEntity<TourDto> createTour(
            @RequestBody TourCreateRequest request,
            Authentication authentication
    ) {

        User loggedInUser = (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                tourService.createTour(
                        request,
                        loggedInUser.getId()
                )
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<TourDto> getTourById(
            @PathVariable Long id
    ) {

        return ResponseEntity.ok(
                tourService.getTourById(id)
        );
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TourDto>> getToursByUserId(
            @PathVariable Long userId
    ) {

        return ResponseEntity.ok(
                tourService.getToursByUserId(userId)
        );
    }

    @PutMapping(
            "/{tourId}/places/{historicalPlaceId}/complete"
    )
    public ResponseEntity<TourDto> markPlaceCompleted(
            @PathVariable Long tourId,
            @PathVariable Long historicalPlaceId
    ) {

        return ResponseEntity.ok(
                tourService.markPlaceCompleted(
                        tourId,
                        historicalPlaceId
                )
        );
    }

    @PutMapping("/{tourId}/complete")
    public ResponseEntity<TourDto> completeTour(
            @PathVariable Long tourId
    ) {

        return ResponseEntity.ok(
                tourService.completeTour(tourId)
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTour(
            @PathVariable Long id
    ) {

        tourService.deleteTour(id);

        return ResponseEntity.noContent().build();
    }
}