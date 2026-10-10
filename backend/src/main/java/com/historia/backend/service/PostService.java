package com.historia.backend.service;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostCommentCreateRequest;
import com.historia.backend.dto.PostCommentDto;
import com.historia.backend.dto.PostDto;

import java.util.List;

public interface PostService {

    List<PostDto> getAllPosts(Long loggedInUserId);

    PostDto getPostById(
            Long id,
            Long loggedInUserId
    );

    PostDto createPost(
            PostCreateRequest request,
            Long loggedInUserId
    );

    PostDto likePost(
            Long id,
            Long loggedInUserId
    );

    List<PostCommentDto> getComments(
            Long postId,
            Long loggedInUserId
    );

    PostCommentDto addComment(
            Long postId,
            PostCommentCreateRequest request,
            Long loggedInUserId
    );

    PostCommentDto likeComment(
            Long postId,
            Long commentId,
            Long loggedInUserId
    );

    void deletePost(
            Long id,
            Long loggedInUserId
    );
}
