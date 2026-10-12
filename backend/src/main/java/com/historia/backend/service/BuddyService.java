package com.historia.backend.service;

import com.historia.backend.dto.*;

import java.time.LocalDate;
import java.util.List;

public interface BuddyService {

    List<BuddyMatchDto> findBuddies(
            Long placeId,
            LocalDate date,
            Long loggedInUserId
    );

    BuddyRequestDto sendRequest(
            Long receiverId,
            Long tourId,
            Long placeId,
            LocalDate date,
            Long loggedInUserId
    );

    BuddyRequestDto acceptRequest(
            Long requestId,
            Long loggedInUserId
    );

    BuddyRequestDto rejectRequest(
            Long requestId,
            Long loggedInUserId
    );

    List<BuddyRequestDto> getReceivedRequests(
            Long loggedInUserId
    );

    List<BuddyRequestDto> getSentRequests(
            Long loggedInUserId
    );

    List<BuddyConversationDto> getConversations(
            Long loggedInUserId
    );

    BuddyMessageDto sendMessage(
            Long requestId,
            String message,
            Long loggedInUserId
    );

    List<BuddyMessageDto> getMessages(
            Long requestId,
            Long loggedInUserId
    );

    void markMessagesAsRead(
            Long requestId,
            Long loggedInUserId
    );

    void validateChatAccess(
            Long requestId,
            Long loggedInUserId
    );
}
