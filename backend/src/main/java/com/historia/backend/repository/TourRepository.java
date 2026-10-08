package com.historia.backend.repository;

import com.historia.backend.entity.Tour;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TourRepository extends JpaRepository<Tour, Long> {

    List<Tour> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Optional<Tour> findByIdAndUser_Id(
            Long tourId,
            Long userId
    );


    @Query("""
    SELECT DISTINCT t
    FROM Tour t
    JOIN t.tourPlaces tp
    WHERE t.tourDate = :date
      AND tp.historicalPlace.id = :placeId
      AND t.user.id <> :userId
""")
    List<Tour> findBuddyTours(
            @Param("placeId") Long placeId,
            @Param("date") LocalDate date,
            @Param("userId") Long userId
    );
}