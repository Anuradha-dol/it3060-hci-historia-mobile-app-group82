package com.historia.backend.service;

import com.historia.backend.dto.NotificationDto;
import com.historia.backend.entity.User;
import com.historia.backend.enums.Role;

import java.util.List;

public interface NotificationService {

    List<NotificationDto.NotificationResponse> getForUser(Long userId);

    NotificationDto.UnreadCountResponse unreadCount(Long userId);

    NotificationDto.NotificationResponse markRead(Long userId, Long notificationId);

    void markAllRead(Long userId);

    NotificationDto.NotificationResponse notifyUser(
            User recipient,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String actionRoute
    );

    void notifyRole(
            Role role,
            String type,
            String title,
            String message,
            String referenceType,
            String referenceId,
            String actionRoute
    );
}
