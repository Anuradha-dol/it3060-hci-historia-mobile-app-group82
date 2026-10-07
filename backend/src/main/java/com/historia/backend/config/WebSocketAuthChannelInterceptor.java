package com.historia.backend.config;

import com.historia.backend.entity.User;
import com.historia.backend.enums.Role;
import com.historia.backend.security.CustomUserDetailsService;
import com.historia.backend.security.JwtService;
import com.historia.backend.service.BuddyService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.List;

@Component
@RequiredArgsConstructor
public class WebSocketAuthChannelInterceptor implements ChannelInterceptor {

    private static final String BUDDY_TOPIC_PREFIX = "/topic/buddies/";
    private static final String BUDDY_SEND_PREFIX = "/app/buddies/";

    private final JwtService jwtService;
    private final CustomUserDetailsService userDetailsService;
    private final BuddyService buddyService;

    @Override
    public Message<?> preSend(
            Message<?> message,
            MessageChannel channel
    ) {

        StompHeaderAccessor accessor =
                StompHeaderAccessor.wrap(message);

        StompCommand command = accessor.getCommand();

        if (command == null) {
            return message;
        }

        if (command == StompCommand.CONNECT) {
            accessor.setUser(authenticate(accessor));
            return message;
        }

        if (command == StompCommand.SUBSCRIBE ||
                command == StompCommand.SEND) {
            User user = userFromPrincipal(accessor.getUser());

            if (user == null) {
                UsernamePasswordAuthenticationToken authentication =
                        authenticate(accessor);
                accessor.setUser(authentication);
                user = (User) authentication.getPrincipal();
            }

            Long requestId = buddyRequestId(accessor.getDestination());

            if (requestId != null) {
                buddyService.validateChatAccess(
                        requestId,
                        user.getId()
                );
            }
        }

        return message;
    }

    private UsernamePasswordAuthenticationToken authenticate(
            StompHeaderAccessor accessor
    ) {

        String authorization =
                firstNativeHeader(accessor, "Authorization");

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

        return new UsernamePasswordAuthenticationToken(
                user,
                null,
                user.getAuthorities()
        );
    }

    private User userFromPrincipal(Principal principal) {
        if (!(principal instanceof UsernamePasswordAuthenticationToken token) ||
                !(token.getPrincipal() instanceof User user)) {
            return null;
        }

        return user;
    }

    private String firstNativeHeader(
            StompHeaderAccessor accessor,
            String name
    ) {

        List<String> headers = accessor.getNativeHeader(name);

        if (headers == null || headers.isEmpty()) {
            return null;
        }

        return headers.get(0);
    }

    private Long buddyRequestId(String destination) {
        if (destination == null) {
            return null;
        }

        String value;

        if (destination.startsWith(BUDDY_TOPIC_PREFIX)) {
            value = destination.substring(BUDDY_TOPIC_PREFIX.length());
        } else if (destination.startsWith(BUDDY_SEND_PREFIX)) {
            value = destination.substring(BUDDY_SEND_PREFIX.length());
        } else {
            return null;
        }

        String id = value.split("/", 2)[0];

        try {
            return Long.parseLong(id);
        } catch (NumberFormatException exception) {
            throw new RuntimeException("Invalid chat destination");
        }
    }
}
