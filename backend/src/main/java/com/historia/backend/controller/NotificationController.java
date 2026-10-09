package com.historia.backend.controller;

import com.historia.backend.dto.NotificationDto;
import com.historia.backend.entity.User;
import com.historia.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/me")
    public List<NotificationDto.NotificationResponse> mine(
            @AuthenticationPrincipal User user
    ) {
        return notificationService.getForUser(user.getId());
    }

    @GetMapping("/me/unread-count")
    public NotificationDto.UnreadCountResponse unreadCount(
            @AuthenticationPrincipal User user
    ) {
        return notificationService.unreadCount(user.getId());
    }

    @PatchMapping("/{id}/read")
    public NotificationDto.NotificationResponse markRead(
            @AuthenticationPrincipal User user,
            @PathVariable Long id
    ) {
        return notificationService.markRead(user.getId(), id);
    }

    @PatchMapping("/read-all")
    public void markAllRead(@AuthenticationPrincipal User user) {
        notificationService.markAllRead(user.getId());
    }
}
