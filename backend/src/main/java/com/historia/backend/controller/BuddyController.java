package com.historia.backend.controller;

import com.historia.backend.dto.*;
import com.historia.backend.entity.User;
import com.historia.backend.service.BuddyService;

import lombok.RequiredArgsConstructor;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/buddies")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TOURIST')")
public class BuddyController {

    private final BuddyService buddyService;

    private final SimpMessagingTemplate messagingTemplate;


    @GetMapping("/search")
    public ResponseEntity<List<BuddyMatchDto>> search(
            @RequestParam Long placeId,
            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.findBuddies(
                        placeId,
                        date,
                        user.getId()
                )
        );
    }


    @PostMapping("/requests")
    public ResponseEntity<BuddyRequestDto>
    sendRequest(
            @RequestParam Long receiverId,
            @RequestParam(required = false) Long tourId,
            @RequestParam(required = false) Long receiverTourId,
            @RequestParam Long placeId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        Long matchedTourId =
                tourId != null ? tourId : receiverTourId;

        if (matchedTourId == null) {
            throw new RuntimeException("Tour is required");
        }

        return ResponseEntity.ok(
                buddyService.sendRequest(
                        receiverId,
                        matchedTourId,
                        placeId,
                        date,
                        user.getId()
                )
        );
    }


    @GetMapping("/requests/received")
    public ResponseEntity<List<BuddyRequestDto>>
    receivedRequests(
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.getReceivedRequests(
                        user.getId()
                )
        );
    }


    @GetMapping("/requests/sent")
    public ResponseEntity<List<BuddyRequestDto>>
    sentRequests(
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.getSentRequests(
                        user.getId()
                )
        );
    }


    @GetMapping("/conversations")
    public ResponseEntity<List<BuddyConversationDto>>
    conversations(
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.getConversations(
                        user.getId()
                )
        );
    }


    @PutMapping("/requests/{requestId}/accept")
    public ResponseEntity<BuddyRequestDto>
    acceptRequest(
            @PathVariable Long requestId,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.acceptRequest(
                        requestId,
                        user.getId()
                )
        );
    }


    @PutMapping("/requests/{requestId}/reject")
    public ResponseEntity<BuddyRequestDto>
    rejectRequest(
            @PathVariable Long requestId,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.rejectRequest(
                        requestId,
                        user.getId()
                )
        );
    }


    @PostMapping("/{requestId}/messages")
    public ResponseEntity<BuddyMessageDto>
    sendMessage(
            @PathVariable Long requestId,
            @RequestBody BuddyMessageRequest body,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        BuddyMessageDto message =
                buddyService.sendMessage(
                        requestId,
                        body.getMessage(),
                        user.getId()
                );

        messagingTemplate.convertAndSend(
                "/topic/buddies/" + requestId,
                message
        );

        return ResponseEntity.ok(message);
    }


    @GetMapping("/{requestId}/messages")
    public ResponseEntity<List<BuddyMessageDto>>
    getMessages(
            @PathVariable Long requestId,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        return ResponseEntity.ok(
                buddyService.getMessages(
                        requestId,
                        user.getId()
                )
        );
    }


    @PutMapping("/{requestId}/read")
    public ResponseEntity<Void>
    markRead(
            @PathVariable Long requestId,
            Authentication authentication) {

        User user =
                (User) authentication.getPrincipal();

        buddyService.markMessagesAsRead(
                requestId,
                user.getId()
        );

        messagingTemplate.convertAndSend(
                "/topic/buddies/" + requestId + "/seen",
                (Object) Map.of("readerId", user.getId())
        );

        return ResponseEntity.noContent().build();
    }
}
