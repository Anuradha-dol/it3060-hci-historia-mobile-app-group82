package com.historia.backend.repository;

import com.historia.backend.entity.GuideProfile;
import com.historia.backend.entity.User;
import com.historia.backend.enums.GuideApplicationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GuideProfileRepository
        extends JpaRepository<GuideProfile, Long> {

    Optional<GuideProfile> findByUser(User user);

    Optional<GuideProfile> findByUserId(Long userId);

    boolean existsByUser(User user);

    List<GuideProfile> findByStatus(
            GuideApplicationStatus status
    );

    List<GuideProfile> findByPrimaryServiceAreaIgnoreCase(
            String primaryServiceArea
    );
}