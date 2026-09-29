package com.historia.backend.controller;

import com.historia.backend.dto.UserDto;
import com.historia.backend.service.ForgotPasswordService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth/password")
public class ForgotPasswordController {

    private final ForgotPasswordService forgotPasswordService;

    public ForgotPasswordController(
            ForgotPasswordService forgotPasswordService
    ) {
        this.forgotPasswordService = forgotPasswordService;
    }


    // Forgot password
    @PostMapping("/forgot")
    public ResponseEntity<UserDto.MessageResponse> forgotPassword(
            @Valid @RequestBody UserDto.ForgotPasswordRequest request
    ) {

        return ResponseEntity.ok(
                forgotPasswordService.requestReset(request)
        );
    }


    // Verify reset OTP
    @PostMapping("/verify")
    public ResponseEntity<UserDto.MessageResponse> verifyOtp(
            @Valid @RequestBody UserDto.ForgotPasswordVerifyRequest request
    ) {

        return ResponseEntity.ok(
                forgotPasswordService.verifyOtp(request)
        );
    }


    // Resend reset OTP
    @PostMapping("/resend")
    public ResponseEntity<UserDto.MessageResponse> resendOtp(
            @Valid @RequestBody UserDto.ForgotPasswordResendRequest request
    ) {

        return ResponseEntity.ok(
                forgotPasswordService.resendOtp(request)
        );
    }


    // Reset password
    @PostMapping("/reset")
    public ResponseEntity<UserDto.MessageResponse> resetPassword(
            @Valid @RequestBody UserDto.ResetPasswordRequest request
    ) {

        return ResponseEntity.ok(
                forgotPasswordService.resetPassword(request)
        );
    }
}