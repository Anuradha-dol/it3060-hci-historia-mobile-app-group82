package com.historia.backend.service;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostDto;

import java.util.List;

public interface PostService {

    List<PostDto> getAllPosts();

    PostDto getPostById(Long id);

    PostDto createPost(
            PostCreateRequest request,
            Long loggedInUserId
    );

    PostDto likePost(Long id);

    void deletePost(
            Long id,
            Long loggedInUserId
    );
}