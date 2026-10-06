package com.historia.backend.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class PostCreateRequest {

    private Long userId;

    private Long historicalPlaceId;

    private String customPlaceName;

    private String caption;

    private List<String> imageUrls;
}
