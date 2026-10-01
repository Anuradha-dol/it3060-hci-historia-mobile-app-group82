package com.historia.backend.controller;

import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.service.HistoricalPlaceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/places")
public class HistoricalPlaceController {

    private final HistoricalPlaceService historicalPlaceService;

    public HistoricalPlaceController(
            HistoricalPlaceService historicalPlaceService) {
        this.historicalPlaceService = historicalPlaceService;
    }

    @GetMapping
    public ResponseEntity<List<HistoricalPlace>> getAllPlaces() {

        return ResponseEntity.ok(
                historicalPlaceService.getAllPlaces()
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<HistoricalPlace> getPlaceById(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                historicalPlaceService.getPlaceById(id)
        );
    }

    @GetMapping("/search")
    public ResponseEntity<List<HistoricalPlace>> searchPlaces(
            @RequestParam String query) {

        return ResponseEntity.ok(
                historicalPlaceService.searchPlaces(query)
        );
    }

    @PostMapping
    public ResponseEntity<HistoricalPlace> createPlace(
            @RequestBody HistoricalPlace historicalPlace) {

        return ResponseEntity.ok(
                historicalPlaceService.createPlace(historicalPlace)
        );
    }

    @PutMapping("/{id}")
    public ResponseEntity<HistoricalPlace> updatePlace(
            @PathVariable Long id,
            @RequestBody HistoricalPlace historicalPlace) {

        return ResponseEntity.ok(
                historicalPlaceService.updatePlace(id, historicalPlace)
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlace(
            @PathVariable Long id) {

        historicalPlaceService.deletePlace(id);

        return ResponseEntity.noContent().build();
    }
}