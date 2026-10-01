package com.historia.backend.repository;

import com.historia.backend.entity.HistoricalPlace;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HistoricalPlaceRepository
        extends JpaRepository<HistoricalPlace, Long> {

    List<HistoricalPlace> findByNameContainingIgnoreCase(String name);
}