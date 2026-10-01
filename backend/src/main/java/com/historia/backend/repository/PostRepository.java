package com.historia.backend.repository;

import com.historia.backend.entity.Post;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PostRepository extends JpaRepository<Post, Long> {

    List<Post> findAllByOrderByCreatedAtDesc();

    Optional<Post> findByIdAndUser_Id(
            Long postId,
            Long userId
    );
}