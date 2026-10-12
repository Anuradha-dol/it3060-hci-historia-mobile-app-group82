package com.historia.backend.repository;

import com.historia.backend.entity.AppNotification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<AppNotification, Long> {

    List<AppNotification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId);

    Optional<AppNotification> findByIdAndRecipientId(Long id, Long recipientId);

    long countByRecipientIdAndReadFalse(Long recipientId);
}
