package com.historia.backend.controller;

import com.historia.backend.dto.UserDto;
import com.historia.backend.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }


    // Registration
    @PostMapping("/register")
    public ResponseEntity<UserDto.MessageResponse> register(
            @Valid @RequestBody UserDto.RegisterRequest request
    ) {

        return ResponseEntity.ok(
                authService.register(request)
        );
    }


    // Verify email
    @PostMapping("/verify-email")
    public ResponseEntity<UserDto.MessageResponse> verifyEmail(
            @Valid @RequestBody UserDto.VerifyOtpRequest request
    ) {

        return ResponseEntity.ok(
                authService.verifyEmail(request)
        );
    }


    // Resend OTP
    @PostMapping("/resend-otp")
    public ResponseEntity<UserDto.MessageResponse> resendOtp(
            @Valid @RequestBody UserDto.ResendOtpRequest request
    ) {

        return ResponseEntity.ok(
                authService.resendOtp(request)
        );
    }


    // Login
    @PostMapping("/login")
    public ResponseEntity<UserDto.AuthResponse> login(
            @Valid @RequestBody UserDto.LoginRequest request
    ) {

        return ResponseEntity.ok(
                authService.login(request)
        );
    }


    // Refresh token
    @PostMapping("/refresh")
    public ResponseEntity<UserDto.AuthResponse> refreshToken(
            @Valid @RequestBody UserDto.RefreshTokenRequest request
    ) {

        return ResponseEntity.ok(
                authService.refreshToken(request)
        );
    }


    // Google login
    @PostMapping("/google")
    public ResponseEntity<UserDto.AuthResponse> googleLogin(
            @Valid @RequestBody UserDto.GoogleLoginRequest request
    ) {

        return ResponseEntity.ok(
                authService.googleLogin(request)
        );
    }
}