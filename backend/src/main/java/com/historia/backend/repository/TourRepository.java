package com.historia.backend.repository;

import com.historia.backend.entity.Tour;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TourRepository extends JpaRepository<Tour, Long> {

    List<Tour> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Optional<Tour> findByIdAndUser_Id(
            Long tourId,
            Long userId
    );
}