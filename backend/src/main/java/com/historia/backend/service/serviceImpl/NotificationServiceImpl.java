package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.NotificationDto;
import com.historia.backend.entity.AppNotification;
import com.historia.backend.entity.User;
import com.historia.backend.enums.Role;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.NotificationRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

    private static final int MAX_TITLE_LENGTH = 120;
    private static final int MAX_MESSAGE_LENGTH = 600;
    private static final String TOPIC_PREFIX = "/topic/notifications/";

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional(readOnly = true)
    public List<NotificationDto.NotificationResponse> getForUser(Long userId) {
        return notificationRepository
                .findByRecipientIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationDto.UnreadCountResponse unreadCount(Long userId) {
        return new NotificationDto.UnreadCountResponse(
                notificationRepository.countByRecipientIdAndReadFalse(userId)
        );
    }

    @Override
    @Transactional
    public NotificationDto.NotificationResponse markRead(
            Long userId,
            Long notificationId
    ) {
        AppNotification notification = notificationRepository
                .findByIdAndRecipientId(notificationId, userId)
                .orElseThrow(() -> new UserException("Notification not found"));

        notification.setRead(true);

        return toResponse(notificationRepository.save(notification));
    }

    @Override
    @Transactional
    public void markAllRead(Long userId) {
        List<AppNotification> notifications =
                notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId);

        for (AppNotification notification : notifications) {
            notification.setRead(true);
        }

        notificationRepository.saveAll(notifications);
    }

    @Override
    @Transactional
    public NotificationDto.NotificationResponse notifyUser(
            User recipient,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String actionRoute
    ) {
        if (recipient == null || recipient.isDeleted()) {
            return null;
        }

        AppNotification notification = AppNotification.builder()
                .recipient(recipient)
                .recipientRole(recipient.getRole())
                .type(cleanType(type))
                .title(limit(title, MAX_TITLE_LENGTH))
                .message(limit(message, MAX_MESSAGE_LENGTH))
                .referenceType(blankToNull(referenceType))
                .referenceId(blankToNull(referenceId))
                .actionRoute(blankToNull(actionRoute))
                .read(false)
                .build();

        NotificationDto.NotificationResponse response =
                toResponse(notificationRepository.save(notification));

        messagingTemplate.convertAndSend(
                TOPIC_PREFIX + recipient.getId(),
                response
        );

        return response;
    }

    @Override
    @Transactional
    public void notifyRole(
            Role role,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String actionRoute
    ) {
        userRepository
                .findByRoleAndDeletedFalse(role)
                .forEach(user -> notifyUser(
                        user,
                        type,
                        title,
                        message,
                        referenceType,
                        referenceId,
                        actionRoute
                ));
    }

    private NotificationDto.NotificationResponse toResponse(
            AppNotification notification
    ) {
        return new NotificationDto.NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getRecipientRole().name(),
                notification.getReferenceType(),
                notification.getReferenceId(),
                notification.getActionRoute(),
                notification.isRead(),
                notification.getCreatedAt()
        );
    }

    private String cleanType(String value) {
        String normalized = blankToNull(value);

        return normalized == null ? "GENERAL" : normalized.toUpperCase();
    }

    private String limit(String value, int maxLength) {
        String normalized = blankToNull(value);

        if (normalized == null) {
            return "";
        }

        if (normalized.length() <= maxLength) {
            return normalized;
        }

        return normalized.substring(0, maxLength - 3).trim() + "...";
    }

    private String blankToNull(String value) {
        if (value == null) {
            return null;
        }

        String trimmed = value.trim();

        return trimmed.isEmpty() ? null : trimmed;
    }
}
