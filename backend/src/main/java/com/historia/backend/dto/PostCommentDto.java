package com.historia.backend.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class PostCommentDto {

    private Long id;

    private Long postId;

    private Long userId;

    private String username;

    private String userRole;

    private String commentText;

    private Integer likeCount;

    private boolean likedByCurrentUser;

    private LocalDateTime createdAt;
}
