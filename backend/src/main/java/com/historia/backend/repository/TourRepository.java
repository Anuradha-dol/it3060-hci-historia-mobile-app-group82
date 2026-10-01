package com.historia.backend.repository;

import com.historia.backend.entity.Tour;
import com.historia.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TourRepository extends JpaRepository<Tour, Long> {

    List<Tour> findByUserIdOrderByCreatedAtDesc(Long userId);
}