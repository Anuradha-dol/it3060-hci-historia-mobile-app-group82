package com.historia.backend.repository;


import com.historia.backend.entity.BuddyMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BuddyMessageRepository
        extends JpaRepository<BuddyMessage, Long> {

    List<BuddyMessage>
    findByBuddyRequestIdOrderBySentAtAsc(
            Long buddyRequestId
    );

    Optional<BuddyMessage>
    findFirstByBuddyRequestIdOrderBySentAtDesc(
            Long buddyRequestId
    );

    long countByBuddyRequestIdAndSenderIdNotAndReadAtIsNull(
            Long buddyRequestId,
            Long senderId
    );

    List<BuddyMessage> findByBuddyRequestIdAndSenderIdNotAndReadAtIsNull(
            Long buddyRequestId,
            Long senderId
    );
}
