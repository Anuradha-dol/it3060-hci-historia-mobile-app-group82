package com.historia.backend.repository;

import com.historia.backend.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByBookingId(Long bookingId);

    List<Review> findByTouristIdOrderByCreatedAtDesc(Long touristId);

    List<Review> findByGuideProfileIdOrderByCreatedAtDesc(Long guideProfileId);

    List<Review> findByGuideProfileId(Long guideProfileId);
}
