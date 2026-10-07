package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostCommentCreateRequest;
import com.historia.backend.dto.PostCommentDto;
import com.historia.backend.dto.PostDto;
import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.entity.Post;
import com.historia.backend.entity.PostComment;
import com.historia.backend.entity.User;
import com.historia.backend.repository.HistoricalPlaceRepository;
import com.historia.backend.repository.PostCommentRepository;
import com.historia.backend.repository.PostRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.PostService;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
public class PostServiceImpl implements PostService {

    private final PostRepository postRepository;
    private final PostCommentRepository postCommentRepository;
    private final UserRepository userRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;

    public PostServiceImpl(
            PostRepository postRepository,
            PostCommentRepository postCommentRepository,
            UserRepository userRepository,
            HistoricalPlaceRepository historicalPlaceRepository
    ) {

        this.postRepository = postRepository;
        this.postCommentRepository = postCommentRepository;
        this.userRepository = userRepository;
        this.historicalPlaceRepository = historicalPlaceRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<PostDto> getAllPosts() {

        return postRepository
                .findAllByOrderByCreatedAtDesc()
                .stream()
                .map(this::convertToDto)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public PostDto getPostById(Long id) {

        Post post = postRepository
                .findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found")
                );

        return convertToDto(post);
    }

    @Override
    @Transactional
    public PostDto createPost(
            PostCreateRequest request,
            Long loggedInUserId
    ) {

        // Logged-in user can only create a post
        // using their own user ID
        if (!loggedInUserId.equals(request.getUserId())) {

            throw new RuntimeException(
                    "You can only create posts for your own account"
            );
        }

        User loggedInUser = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Logged in user not found"
                        )
                );

        HistoricalPlace historicalPlace = null;
        String customPlaceName = cleanText(
                request.getCustomPlaceName()
        );

        if (request.getHistoricalPlaceId() != null) {
            historicalPlace =
                    historicalPlaceRepository
                            .findById(
                                    request.getHistoricalPlaceId()
                            )
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "Historical place not found"
                                    )
                            );
        }

        if (historicalPlace == null && customPlaceName == null) {
            throw new RuntimeException(
                    "Please select or type a historical place"
            );
        }

        Post post = Post.builder()
                .user(loggedInUser)
                .historicalPlace(historicalPlace)
                .customPlaceName(customPlaceName)
                .caption(request.getCaption())
                .imageUrls(
                        request.getImageUrls() != null
                                ? new ArrayList<>(
                                request.getImageUrls()
                        )
                                : new ArrayList<>()
                )
                .likeCount(0)
                .commentCount(0)
                .build();

        Post savedPost =
                postRepository.save(post);

        return convertToDto(savedPost);
    }

    @Override
    @Transactional
    public PostDto likePost(Long id) {

        Post post = postRepository
                .findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found")
                );

        int currentLikeCount =
                post.getLikeCount() == null
                        ? 0
                        : post.getLikeCount();

        post.setLikeCount(
                currentLikeCount + 1
        );

        Post updatedPost =
                postRepository.save(post);

        return convertToDto(updatedPost);
    }

    @Override
    @Transactional(readOnly = true)
    public List<PostCommentDto> getComments(Long postId) {

        if (!postRepository.existsById(postId)) {
            throw new RuntimeException("Post not found");
        }

        return postCommentRepository
                .findByPost_IdOrderByCreatedAtAsc(postId)
                .stream()
                .map(this::convertCommentToDto)
                .toList();
    }

    @Override
    @Transactional
    public PostCommentDto addComment(
            Long postId,
            PostCommentCreateRequest request,
            Long loggedInUserId
    ) {

        String commentText = cleanText(
                request.getCommentText()
        );

        if (commentText == null) {
            throw new RuntimeException(
                    "Comment text is required"
            );
        }

        Post post = postRepository
                .findById(postId)
                .orElseThrow(() ->
                        new RuntimeException("Post not found")
                );

        User loggedInUser = userRepository
                .findById(loggedInUserId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Logged in user not found"
                        )
                );

        PostComment comment = PostComment.builder()
                .post(post)
                .user(loggedInUser)
                .commentText(commentText)
                .likeCount(0)
                .build();

        int currentCommentCount =
                post.getCommentCount() == null
                        ? 0
                        : post.getCommentCount();

        post.setCommentCount(
                currentCommentCount + 1
        );

        postRepository.save(post);

        PostComment savedComment =
                postCommentRepository.save(comment);

        return convertCommentToDto(savedComment);
    }

    @Override
    @Transactional
    public PostCommentDto likeComment(
            Long postId,
            Long commentId
    ) {

        PostComment comment = postCommentRepository
                .findByIdAndPost_Id(commentId, postId)
                .orElseThrow(() ->
                        new RuntimeException("Comment not found")
                );

        int currentLikeCount =
                comment.getLikeCount() == null
                        ? 0
                        : comment.getLikeCount();

        comment.setLikeCount(
                currentLikeCount + 1
        );

        PostComment updatedComment =
                postCommentRepository.save(comment);

        return convertCommentToDto(updatedComment);
    }

    @Override
    @Transactional
    public void deletePost(
            Long id,
            Long loggedInUserId
    ) {

        Post post = postRepository
                .findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found")
                );

        boolean owner =
                post.getUser()
                        .getId()
                        .equals(loggedInUserId);

        if (!owner) {
            throw new AccessDeniedException(
                    "You are not allowed to delete this post"
            );
        }

        postRepository.delete(post);
    }

    private PostDto convertToDto(Post post) {

        return PostDto.builder()
                .id(
                        post.getId()
                )
                .userId(
                        post.getUser().getId()
                )
                .username(
                        post.getUser().getUsername()
                )
                .userRole(
                        post.getUser()
                                .getRole()
                                .name()
                )
                .historicalPlaceId(
                        post.getHistoricalPlace() != null
                                ? post.getHistoricalPlace()
                                .getId()
                                : null
                )
                .historicalPlaceName(
                        post.getHistoricalPlace() != null
                                ? post.getHistoricalPlace()
                                .getName()
                                : post.getCustomPlaceName()
                )
                .customPlaceName(
                        post.getCustomPlaceName()
                )
                .caption(
                        post.getCaption()
                )
                .imageUrls(
                        post.getImageUrls() != null
                                ? new ArrayList<>(
                                post.getImageUrls()
                        )
                                : new ArrayList<>()
                )
                .likeCount(
                        post.getLikeCount()
                )
                .commentCount(
                        post.getCommentCount()
                )
                .createdAt(
                        post.getCreatedAt()
                )
                .build();
    }

    private PostCommentDto convertCommentToDto(
            PostComment comment
    ) {

        return PostCommentDto.builder()
                .id(comment.getId())
                .postId(comment.getPost().getId())
                .userId(comment.getUser().getId())
                .username(comment.getUser().getUsername())
                .userRole(comment.getUser().getRole().name())
                .commentText(comment.getCommentText())
                .likeCount(comment.getLikeCount())
                .createdAt(comment.getCreatedAt())
                .build();
    }

    private String cleanText(String value) {

        if (value == null) {
            return null;
        }

        String trimmed = value.trim();

        return trimmed.isEmpty()
                ? null
                : trimmed;
    }
}
