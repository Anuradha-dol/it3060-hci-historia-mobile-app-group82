package com.historia.backend.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuddyMessageDto {

    private Long id;

    private Long senderId;

    private String senderUsername;

    private String message;

    private LocalDateTime sentAt;

    private boolean read;
}
