package com.historia.backend.repository;

import com.historia.backend.entity.PostComment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PostCommentRepository
        extends JpaRepository<PostComment, Long> {

    List<PostComment> findByPost_IdOrderByCreatedAtAsc(Long postId);

    Optional<PostComment> findByIdAndPost_Id(
            Long commentId,
            Long postId
    );
}
