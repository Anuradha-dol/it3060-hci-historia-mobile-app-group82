package com.historia.backend.controller;

import com.historia.backend.dto.BuddyMessageDto;
import com.historia.backend.dto.BuddyMessageRequest;
import com.historia.backend.entity.User;
import com.historia.backend.enums.Role;
import com.historia.backend.security.CustomUserDetailsService;
import com.historia.backend.security.JwtService;
import com.historia.backend.service.BuddyService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
@RequiredArgsConstructor
public class BuddyWebSocketController {

    private final BuddyService buddyService;
    private final SimpMessagingTemplate messagingTemplate;
    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;

    @MessageMapping("/buddies/{requestId}/send")
    public void sendBuddyMessage(
            @DestinationVariable Long requestId,
            @Payload BuddyMessageRequest body,
            Message<?> message
    ) {

        User user = authenticate(message);

        BuddyMessageDto savedMessage =
                buddyService.sendMessage(
                        requestId,
                        body.getMessage(),
                        user.getId()
                );

        messagingTemplate.convertAndSend(
                "/topic/buddies/" + requestId,
                savedMessage
        );
    }

    private User authenticate(Message<?> message) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(
                        message,
                        StompHeaderAccessor.class
                );

        String authorization = firstNativeHeader(
                accessor,
                "Authorization"
        );

        if (authorization == null ||
                !authorization.startsWith("Bearer ")) {
            throw new RuntimeException("Authentication required");
        }

        String token = authorization.substring(7);
        String username = jwtService.extractUsername(token);
        UserDetails userDetails =
                userDetailsService.loadUserByUsername(username);

        if (!(userDetails instanceof User user) ||
                !jwtService.isAccessTokenValid(token, user)) {
            throw new RuntimeException("Authentication required");
        }

        if (user.getRole() != Role.TOURIST) {
            throw new RuntimeException("Access denied");
        }

        return user;
    }

    private String firstNativeHeader(
            StompHeaderAccessor accessor,
            String name
    ) {

        if (accessor == null) {
            return null;
        }

        List<String> headers = accessor.getNativeHeader(name);

        if (headers == null || headers.isEmpty()) {
            return null;
        }

        return headers.get(0);
    }
}
