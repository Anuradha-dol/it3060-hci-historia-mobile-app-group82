package com.historia.backend.controller;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostDto;
import com.historia.backend.service.PostService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
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
            @PathVariable Long id) {

        return ResponseEntity.ok(
                postService.getPostById(id)
        );
    }

    @PostMapping
    public ResponseEntity<PostDto> createPost(
            @RequestBody PostCreateRequest request) {

        return ResponseEntity.ok(
                postService.createPost(request)
        );
    }

    @PutMapping("/{id}/like")
    public ResponseEntity<PostDto> likePost(
            @PathVariable Long id) {

        return ResponseEntity.ok(
                postService.likePost(id)
        );
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePost(
            @PathVariable Long id) {

        postService.deletePost(id);

        return ResponseEntity.noContent().build();
    }
}