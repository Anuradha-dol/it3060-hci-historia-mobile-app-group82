package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.PostCreateRequest;
import com.historia.backend.dto.PostDto;
import com.historia.backend.entity.HistoricalPlace;
import com.historia.backend.entity.Post;
import com.historia.backend.entity.User;
import com.historia.backend.repository.HistoricalPlaceRepository;
import com.historia.backend.repository.PostRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.PostService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
public class PostServiceImpl implements PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final HistoricalPlaceRepository historicalPlaceRepository;

    public PostServiceImpl(
            PostRepository postRepository,
            UserRepository userRepository,
            HistoricalPlaceRepository historicalPlaceRepository) {

        this.postRepository = postRepository;
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

        Post post = postRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found"));

        return convertToDto(post);
    }

    @Override
    @Transactional
    public PostDto createPost(PostCreateRequest request) {

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() ->
                        new RuntimeException("User not found"));

        HistoricalPlace historicalPlace =
                historicalPlaceRepository
                        .findById(request.getHistoricalPlaceId())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Historical place not found"
                                ));

        Post post = Post.builder()
                .user(user)
                .historicalPlace(historicalPlace)
                .caption(request.getCaption())
                .imageUrls(
                        request.getImageUrls() != null
                                ? new ArrayList<>(request.getImageUrls())
                                : new ArrayList<>()
                )
                .likeCount(0)
                .build();

        Post savedPost = postRepository.save(post);

        return convertToDto(savedPost);
    }

    @Override
    @Transactional
    public PostDto likePost(Long id) {

        Post post = postRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found"));

        int currentLikeCount =
                post.getLikeCount() == null
                        ? 0
                        : post.getLikeCount();

        post.setLikeCount(currentLikeCount + 1);

        Post updatedPost = postRepository.save(post);

        return convertToDto(updatedPost);
    }

    @Override
    @Transactional
    public void deletePost(Long id) {

        Post post = postRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Post not found"));

        postRepository.delete(post);
    }

    private PostDto convertToDto(Post post) {

        return PostDto.builder()
                .id(post.getId())
                .userId(
                        post.getUser().getId()
                )
                .username(
                        post.getUser().getUsername()
                )
                .historicalPlaceId(
                        post.getHistoricalPlace().getId()
                )
                .historicalPlaceName(
                        post.getHistoricalPlace().getName()
                )
                .caption(
                        post.getCaption()
                )
                .imageUrls(
                        post.getImageUrls() != null
                                ? new ArrayList<>(post.getImageUrls())
                                : new ArrayList<>()
                )
                .likeCount(
                        post.getLikeCount()
                )
                .createdAt(
                        post.getCreatedAt()
                )
                .build();
    }
}