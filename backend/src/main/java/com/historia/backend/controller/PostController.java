package com.historia.backend.controller;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostCommentCreateRequest;
import com.historia.backend.dto.PostCommentDto;
import com.historia.backend.dto.PostDto;
import com.historia.backend.entity.User;
import com.historia.backend.service.PostService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/posts")
@PreAuthorize("hasAnyRole('TOURIST','GUIDE','ADMIN')")
public class PostController {

    private final PostService postService;

    public PostController(
            PostService postService
    ) {
        this.postService = postService;
    }

    @GetMapping
    public ResponseEntity<List<PostDto>> getAllPosts() {

        return ResponseEntity.ok(
                postService.getAllPosts()
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<PostDto> getPostById(
            @PathVariable Long id
    ) {

        return ResponseEntity.ok(
                postService.getPostById(id)
        );
    }

    @PostMapping
    public ResponseEntity<PostDto> createPost(
            @RequestBody PostCreateRequest request,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                postService.createPost(
                        request,
                        loggedInUser.getId()
                )
        );
    }

    @PutMapping("/{id}/like")
    public ResponseEntity<PostDto> likePost(
            @PathVariable Long id
    ) {

        return ResponseEntity.ok(
                postService.likePost(id)
        );
    }

    @GetMapping("/{id}/comments")
    public ResponseEntity<List<PostCommentDto>> getComments(
            @PathVariable Long id
    ) {

        return ResponseEntity.ok(
                postService.getComments(id)
        );
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<PostCommentDto> addComment(
            @PathVariable Long id,
            @RequestBody PostCommentCreateRequest request,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                postService.addComment(
                        id,
                        request,
                        loggedInUser.getId()
                )
        );
    }

    @PutMapping("/{postId}/comments/{commentId}/like")
    public ResponseEntity<PostCommentDto> likeComment(
            @PathVariable Long postId,
            @PathVariable Long commentId
    ) {

        return ResponseEntity.ok(
                postService.likeComment(
                        postId,
                        commentId
                )
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePost(
            @PathVariable Long id,
            Authentication authentication
    ) {

        User loggedInUser =
                (User) authentication.getPrincipal();

        postService.deletePost(
                id,
                loggedInUser.getId()
        );

        return ResponseEntity
                .noContent()
                .build();
    }
}
