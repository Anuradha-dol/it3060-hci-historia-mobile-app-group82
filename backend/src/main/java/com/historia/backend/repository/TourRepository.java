package com.historia.backend.repository;

import com.historia.backend.entity.Tour;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TourRepository extends JpaRepository<Tour, Long> {

    List<Tour> findByUserIdOrderByCreatedAtDesc(Long userId);
}