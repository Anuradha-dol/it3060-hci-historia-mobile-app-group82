package com.historia.backend.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@Builder
public class PostDto {

    private Long id;

    private Long userId;

    private String username;

    private String userRole;

    private Long historicalPlaceId;

    private String historicalPlaceName;

    private String customPlaceName;

    private String caption;

    private List<String> imageUrls;

    private Integer likeCount;

    private Integer commentCount;

    private LocalDateTime createdAt;
}
