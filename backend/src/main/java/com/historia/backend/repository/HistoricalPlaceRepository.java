package com.historia.backend.repository;

import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.enums.Role;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface HistoricalPlaceRepository
        extends JpaRepository<HistoricalPlace, Long> {

    List<HistoricalPlace> findByNameContainingIgnoreCase(String name);

    @Query("""
            SELECT place,
                   COALESCE(SUM(
                       CASE
                           WHEN tourUser.role = :role THEN 1
                           ELSE 0
                       END
                   ), 0)
            FROM HistoricalPlace place
            LEFT JOIN TourPlace tourPlace
                ON tourPlace.historicalPlace = place
            LEFT JOIN tourPlace.tour tour
            LEFT JOIN tour.user tourUser
            GROUP BY place
            ORDER BY COALESCE(SUM(
                       CASE
                           WHEN tourUser.role = :role THEN 1
                           ELSE 0
                       END
                   ), 0) DESC,
                   place.name ASC
            """)
    List<Object[]> findTopPlacesByTourCount(
            @Param("role") Role role,
            Pageable pageable
    );
}
