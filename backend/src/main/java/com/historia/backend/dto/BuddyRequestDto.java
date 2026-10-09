package com.historia.backend.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuddyRequestDto {

    private Long id;

    private Long senderId;

    private String senderUsername;

    private String senderProfileImageUrl;

    private boolean senderOnline;

    private Long receiverId;

    private String receiverUsername;

    private String receiverProfileImageUrl;

    private boolean receiverOnline;

    private Long tourId;

    private Long historicalPlaceId;

    private String historicalPlaceName;

    private String status;

    private LocalDateTime createdAt;
}
