package com.historia.backend.dto;

import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BuddyMatchDto {

    private Long userId;

    private String username;

    private String profileImageUrl;

    private boolean online;

    private Long tourId;

    private String tourTitle;

    private LocalDate tourDate;

    private Long historicalPlaceId;

    private String historicalPlaceName;
}
