package com.historia.backend.repository;

import com.historia.backend.entity.BuddyRequest;

import com.historia.backend.enums.BuddyRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface BuddyRequestRepository
        extends JpaRepository<BuddyRequest, Long> {

    List<BuddyRequest> findByReceiverIdOrderByCreatedAtDesc(
            Long receiverId
    );

    List<BuddyRequest> findBySenderIdOrderByCreatedAtDesc(
            Long senderId
    );

    Optional<BuddyRequest>
    findBySenderIdAndReceiverIdAndTourIdAndHistoricalPlaceId(
            Long senderId,
            Long receiverId,
            Long tourId,
            Long historicalPlaceId
    );

    @Query("""
            SELECT br
            FROM BuddyRequest br
            WHERE br.historicalPlace.id = :placeId
              AND br.status <> com.historia.backend.enums.BuddyRequestStatus.REJECTED
              AND (
                    (br.sender.id = :firstUserId AND br.receiver.id = :secondUserId)
                 OR (br.sender.id = :secondUserId AND br.receiver.id = :firstUserId)
              )
            """)
    List<BuddyRequest> findActiveBetweenUsersForPlace(
            @Param("firstUserId") Long firstUserId,
            @Param("secondUserId") Long secondUserId,
            @Param("placeId") Long placeId
    );

    List<BuddyRequest>
    findByReceiverIdAndStatusOrderByCreatedAtDesc(
            Long receiverId,
            BuddyRequestStatus status
    );

    @Query("""
            SELECT br
            FROM BuddyRequest br
            WHERE br.status = :status
              AND (br.sender.id = :userId OR br.receiver.id = :userId)
            ORDER BY br.createdAt DESC
            """)
    List<BuddyRequest> findByUserIdAndStatusOrderByCreatedAtDesc(
            @Param("userId") Long userId,
            @Param("status") BuddyRequestStatus status
    );
}
