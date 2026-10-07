package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.BuddyConversationDto;
import com.historia.backend.dto.BuddyMatchDto;
import com.historia.backend.dto.BuddyMessageDto;
import com.historia.backend.dto.BuddyRequestDto;
import com.historia.backend.entity.BuddyMessage;
import com.historia.backend.entity.BuddyRequest;
import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.entity.Tour;
import com.historia.backend.entity.User;
import com.historia.backend.enums.BuddyRequestStatus;
import com.historia.backend.repository.BuddyMessageRepository;
import com.historia.backend.repository.BuddyRequestRepository;
import com.historia.backend.repository.HistoricalPlaceRepository;
import com.historia.backend.repository.TourRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.BuddyService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class BuddyServiceImpl implements BuddyService {

    private final TourRepository tourRepository;
    private final UserRepository userRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;
    private final BuddyRequestRepository buddyRequestRepository;
    private final BuddyMessageRepository buddyMessageRepository;

    @Override
    @Transactional(readOnly = true)
    public List<BuddyMatchDto> findBuddies(
            Long placeId,
            LocalDate date,
            Long loggedInUserId
    ) {

        historicalPlaceRepository
                .findById(placeId)
                .orElseThrow(() ->
                        new RuntimeException("Historical place not found")
                );

        return tourRepository
                .findBuddyTours(
                        placeId,
                        date,
                        loggedInUserId
                )
                .stream()
                .map(tour ->
                        BuddyMatchDto.builder()
                                .userId(tour.getUser().getId())
                                .username(displayName(tour.getUser()))
                                .profileImageUrl(
                                        tour.getUser().getProfileImageUrl()
                                )
                                .online(isOnline(tour.getUser()))
                                .tourId(tour.getId())
                                .tourTitle(tour.getTitle())
                                .tourDate(tour.getTourDate())
                                .historicalPlaceId(placeId)
                                .historicalPlaceName(
                                        findPlaceName(tour, placeId)
                                )
                                .build()
                )
                .toList();
    }

    private String findPlaceName(
            Tour tour,
            Long placeId
    ) {

        return tour.getTourPlaces()
                .stream()
                .filter(tp ->
                        tp.getHistoricalPlace()
                                .getId()
                                .equals(placeId)
                )
                .map(tp ->
                        tp.getHistoricalPlace()
                                .getName()
                )
                .findFirst()
                .orElse("");
    }

    @Override
    @Transactional
    public BuddyRequestDto sendRequest(
            Long receiverId,
            Long tourId,
            Long placeId,
            LocalDate date,
            Long loggedInUserId
    ) {

        if (receiverId.equals(loggedInUserId)) {
            throw new RuntimeException(
                    "You cannot send a buddy request to yourself"
            );
        }

        User sender = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException("Sender not found")
                );

        User receiver = userRepository
                .findById(receiverId)
                .orElseThrow(() ->
                        new RuntimeException("Receiver not found")
                );

        Tour receiverTour = tourRepository
                .findById(tourId)
                .orElseThrow(() ->
                        new RuntimeException("Tour not found")
                );

        if (!receiverTour.getUser().getId().equals(receiverId)) {
            throw new RuntimeException(
                    "Selected tour does not belong to this tourist"
            );
        }

        if (date != null &&
                receiverTour.getTourDate() != null &&
                !date.equals(receiverTour.getTourDate())) {
            throw new RuntimeException(
                    "Selected tourist is not visiting on this date"
            );
        }

        HistoricalPlace place =
                historicalPlaceRepository
                        .findById(placeId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Historical place not found"
                                )
                        );

        boolean placeExistsInTour =
                receiverTour.getTourPlaces()
                        .stream()
                        .anyMatch(tp ->
                                tp.getHistoricalPlace()
                                        .getId()
                                        .equals(placeId)
                        );

        if (!placeExistsInTour) {
            throw new RuntimeException(
                    "Selected tourist is not visiting this place"
            );
        }

        buddyRequestRepository
                .findActiveBetweenUsersForPlace(
                        loggedInUserId,
                        receiverId,
                        placeId
                )
                .stream()
                .findFirst()
                .ifPresent(request -> {
                    if (request.getStatus()
                            == BuddyRequestStatus.ACCEPTED) {
                        throw new RuntimeException(
                                "You are already travel buddies"
                        );
                    }

                    throw new RuntimeException(
                            "Buddy request already pending"
                    );
                });

        BuddyRequest buddyRequest =
                BuddyRequest.builder()
                        .sender(sender)
                        .receiver(receiver)
                        .tour(receiverTour)
                        .historicalPlace(place)
                        .status(BuddyRequestStatus.PENDING)
                        .createdAt(LocalDateTime.now())
                        .build();

        return mapRequest(
                buddyRequestRepository.save(buddyRequest)
        );
    }

    @Override
    @Transactional
    public BuddyRequestDto acceptRequest(
            Long requestId,
            Long loggedInUserId
    ) {

        BuddyRequest request =
                getRequestForReceiver(requestId, loggedInUserId);

        if (request.getStatus() != BuddyRequestStatus.PENDING) {
            throw new RuntimeException(
                    "Buddy request is no longer pending"
            );
        }

        request.setStatus(BuddyRequestStatus.ACCEPTED);

        return mapRequest(
                buddyRequestRepository.save(request)
        );
    }

    @Override
    @Transactional
    public BuddyRequestDto rejectRequest(
            Long requestId,
            Long loggedInUserId
    ) {

        BuddyRequest request =
                getRequestForReceiver(requestId, loggedInUserId);

        if (request.getStatus() != BuddyRequestStatus.PENDING) {
            throw new RuntimeException(
                    "Buddy request is no longer pending"
            );
        }

        request.setStatus(BuddyRequestStatus.REJECTED);

        return mapRequest(
                buddyRequestRepository.save(request)
        );
    }

    private BuddyRequest getRequestForReceiver(
            Long requestId,
            Long userId
    ) {

        BuddyRequest request =
                buddyRequestRepository
                        .findById(requestId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Buddy request not found"
                                )
                        );

        if (!request.getReceiver().getId().equals(userId)) {
            throw new RuntimeException(
                    "You cannot update this request"
            );
        }

        return request;
    }

    @Override
    @Transactional(readOnly = true)
    public List<BuddyRequestDto> getReceivedRequests(
            Long loggedInUserId
    ) {

        return buddyRequestRepository
                .findByReceiverIdOrderByCreatedAtDesc(loggedInUserId)
                .stream()
                .map(this::mapRequest)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<BuddyRequestDto> getSentRequests(
            Long loggedInUserId
    ) {

        return buddyRequestRepository
                .findBySenderIdOrderByCreatedAtDesc(loggedInUserId)
                .stream()
                .map(this::mapRequest)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<BuddyConversationDto> getConversations(
            Long loggedInUserId
    ) {

        return buddyRequestRepository
                .findByUserIdAndStatusOrderByCreatedAtDesc(
                        loggedInUserId,
                        BuddyRequestStatus.ACCEPTED
                )
                .stream()
                .map(request -> mapConversation(request, loggedInUserId))
                .sorted(
                        Comparator.comparing(
                                BuddyConversationDto::getLastMessageTime,
                                Comparator.nullsLast(
                                        Comparator.reverseOrder()
                                )
                        )
                )
                .toList();
    }

    @Override
    @Transactional
    public BuddyMessageDto sendMessage(
            Long requestId,
            String message,
            Long loggedInUserId
    ) {

        BuddyRequest request = getRequestForChat(
                requestId,
                loggedInUserId
        );

        if (message == null || message.trim().isEmpty()) {
            throw new RuntimeException(
                    "Message cannot be empty"
            );
        }

        User sender = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException("User not found")
                );

        BuddyMessage buddyMessage =
                BuddyMessage.builder()
                        .buddyRequest(request)
                        .sender(sender)
                        .message(message.trim())
                        .sentAt(LocalDateTime.now())
                        .build();

        return mapMessage(
                buddyMessageRepository.save(buddyMessage)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public List<BuddyMessageDto> getMessages(
            Long requestId,
            Long loggedInUserId
    ) {

        getRequestForChat(requestId, loggedInUserId);

        return buddyMessageRepository
                .findByBuddyRequestIdOrderBySentAtAsc(requestId)
                .stream()
                .map(this::mapMessage)
                .toList();
    }

    @Override
    @Transactional
    public void markMessagesAsRead(
            Long requestId,
            Long loggedInUserId
    ) {

        getRequestForChat(requestId, loggedInUserId);

        List<BuddyMessage> unreadMessages =
                buddyMessageRepository
                        .findByBuddyRequestIdAndSenderIdNotAndReadAtIsNull(
                                requestId,
                                loggedInUserId
                        );

        if (unreadMessages.isEmpty()) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();

        unreadMessages.forEach(message ->
                message.setReadAt(now)
        );

        buddyMessageRepository.saveAll(unreadMessages);
    }

    @Override
    @Transactional(readOnly = true)
    public void validateChatAccess(
            Long requestId,
            Long loggedInUserId
    ) {

        getRequestForChat(requestId, loggedInUserId);
    }

    private BuddyRequest getRequestForChat(
            Long requestId,
            Long userId
    ) {

        BuddyRequest request =
                buddyRequestRepository
                        .findById(requestId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Buddy request not found"
                                )
                        );

        validateChatAccess(request, userId);

        return request;
    }

    private void validateChatAccess(
            BuddyRequest request,
            Long userId
    ) {

        if (request.getStatus() != BuddyRequestStatus.ACCEPTED) {
            throw new RuntimeException(
                    "Buddy request must be accepted before chatting"
            );
        }

        boolean sender = request.getSender().getId().equals(userId);
        boolean receiver = request.getReceiver().getId().equals(userId);

        if (!sender && !receiver) {
            throw new RuntimeException(
                    "You do not have access to this chat"
            );
        }
    }

    private BuddyConversationDto mapConversation(
            BuddyRequest request,
            Long loggedInUserId
    ) {

        boolean iAmSender =
                request.getSender().getId().equals(loggedInUserId);

        User otherUser =
                iAmSender ? request.getReceiver() : request.getSender();

        BuddyMessage lastMessage =
                buddyMessageRepository
                        .findFirstByBuddyRequestIdOrderBySentAtDesc(
                                request.getId()
                        )
                        .orElse(null);

        return BuddyConversationDto.builder()
                .requestId(request.getId())
                .otherUserId(otherUser.getId())
                .username(displayName(otherUser))
                .profileImageUrl(otherUser.getProfileImageUrl())
                .online(isOnline(otherUser))
                .historicalPlaceId(request.getHistoricalPlace().getId())
                .historicalPlaceName(request.getHistoricalPlace().getName())
                .tourId(request.getTour().getId())
                .lastMessage(
                        lastMessage == null
                                ? null
                                : lastMessage.getMessage()
                )
                .lastMessageTime(
                        lastMessage == null
                                ? null
                                : lastMessage.getSentAt()
                )
                .unreadCount(
                        buddyMessageRepository
                                .countByBuddyRequestIdAndSenderIdNotAndReadAtIsNull(
                                        request.getId(),
                                        loggedInUserId
                                )
                )
                .build();
    }

    private BuddyRequestDto mapRequest(
            BuddyRequest request
    ) {

        return BuddyRequestDto.builder()
                .id(request.getId())
                .senderId(request.getSender().getId())
                .senderUsername(displayName(request.getSender()))
                .senderProfileImageUrl(
                        request.getSender().getProfileImageUrl()
                )
                .senderOnline(isOnline(request.getSender()))
                .receiverId(request.getReceiver().getId())
                .receiverUsername(displayName(request.getReceiver()))
                .receiverProfileImageUrl(
                        request.getReceiver().getProfileImageUrl()
                )
                .receiverOnline(isOnline(request.getReceiver()))
                .tourId(request.getTour().getId())
                .historicalPlaceId(
                        request.getHistoricalPlace().getId()
                )
                .historicalPlaceName(
                        request.getHistoricalPlace().getName()
                )
                .status(request.getStatus().name())
                .createdAt(request.getCreatedAt())
                .build();
    }

    private BuddyMessageDto mapMessage(
            BuddyMessage message
    ) {

        return BuddyMessageDto.builder()
                .id(message.getId())
                .senderId(message.getSender().getId())
                .senderUsername(displayName(message.getSender()))
                .message(message.getMessage())
                .sentAt(message.getSentAt())
                .read(message.getReadAt() != null)
                .build();
    }

    private String displayName(User user) {
        String firstName = user.getFirstName() == null
                ? ""
                : user.getFirstName().trim();

        String lastName = user.getLastName() == null
                ? ""
                : user.getLastName().trim();

        String fullName = (firstName + " " + lastName).trim();

        if (!fullName.isBlank()) {
            return fullName;
        }

        return user.getUsername();
    }

    private boolean isOnline(User user) {
        String refreshTokenHash = user.getRefreshTokenHash();

        return user.isEnabled() &&
                refreshTokenHash != null &&
                !refreshTokenHash.isBlank();
    }
}
