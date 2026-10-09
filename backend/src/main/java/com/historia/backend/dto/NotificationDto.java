package com.historia.backend.dto;

import java.time.LocalDateTime;

public final class NotificationDto {

    private NotificationDto() {
    }

    public record NotificationResponse(
            Long id,
            String type,
            String title,
            String message,
            String recipientRole,
            String referenceType,
            String referenceId,
            String actionRoute,
            boolean read,
            LocalDateTime createdAt
    ) {
    }

    public record UnreadCountResponse(long unreadCount) {
    }
}
