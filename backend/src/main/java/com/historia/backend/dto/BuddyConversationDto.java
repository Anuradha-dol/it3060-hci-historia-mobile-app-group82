package com.historia.backend.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuddyConversationDto {

    private Long requestId;

    private Long otherUserId;

    private String username;

    private String profileImageUrl;

    private boolean online;

    private Long historicalPlaceId;

    private String historicalPlaceName;

    private Long tourId;

    private String lastMessage;

    private LocalDateTime lastMessageTime;

    private long unreadCount;
}
