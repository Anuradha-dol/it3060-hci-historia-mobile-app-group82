package com.historia.backend.repository;

import com.historia.backend.entity.Booking;
import com.historia.backend.entity.GuideProfile;
import com.historia.backend.entity.Review;
import com.historia.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByBooking(Booking booking);

    Optional<Review> findByBooking(Booking booking);

    List<Review> findByTouristOrderByCreatedAtDesc(User tourist);

    List<Review> findByGuideProfileOrderByCreatedAtDesc(GuideProfile guideProfile);
}
