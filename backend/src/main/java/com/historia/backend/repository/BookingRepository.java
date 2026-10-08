package com.historia.backend.repository;

import com.historia.backend.entity.Booking;
import com.historia.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BookingRepository extends JpaRepository<Booking, Long> {

    Optional<Booking> findByIdAndTourist(Long id, User tourist);

    List<Booking> findByTouristOrderByCreatedAtDesc(User tourist);
}
