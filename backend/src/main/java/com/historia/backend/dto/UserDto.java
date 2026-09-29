package com.historia.backend.dto;

import com.historia.backend.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class UserDto {

    // Registration
    public record RegisterRequest(

            @NotBlank(message = "Username is required")
            String username,

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Phone number is required")
            String phone,

            @NotBlank(message = "Password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String password,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword,

            String firstName,

            String lastName,

            String address,

            @NotNull(message = "Role is required")
            Role role

    ) {}


    // Login
    public record LoginRequest(

            @NotBlank(message = "Email, username or phone is required")
            String identifier,

            @NotBlank(message = "Password is required")
            String password

    ) {}


    // Login response
    public record AuthResponse(

            String accessToken,

            String refreshToken,

            UserProfileResponse user

    ) {}


    // Refresh token
    public record RefreshTokenRequest(

            @NotBlank(message = "Refresh token is required")
            String refreshToken

    ) {}


    // Verify email
    public record VerifyOtpRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Verification code is required")
            String code

    ) {}


    // Resend OTP
    public record ResendOtpRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email

    ) {}


    // Update profile
    public record UpdateProfileRequest(

            String firstName,

            String lastName,

            String phone,

            String address

    ) {}


    // Change password
    public record ChangePasswordRequest(

            @NotBlank(message = "Current password is required")
            String currentPassword,

            @NotBlank(message = "New password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String newPassword,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword

    ) {}


    // Forgot password
    public record ForgotPasswordRequest(

            String username,

            @Email(message = "Please provide a valid email")
            String email,

            String phone

    ) {}


    // Verify reset OTP
    public record ForgotPasswordVerifyRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Verification code is required")
            String code

    ) {}

    // Resend reset OTP
    public record ForgotPasswordResendRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email

    ) {}


    // Reset password
    public record ResetPasswordRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "New password is required")
            @Size(min = 8, message = "Password must be at least 8 characters")
            String newPassword,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword

    ) {}


    // Delete account
    public record DeleteAccountRequest(

            @NotBlank(message = "Current password is required")
            String currentPassword

    ) {}


    // Profile response
    public record UserProfileResponse(

            Long id,

            String username,

            String email,

            String phone,

            String firstName,

            String lastName,

            String address,

            Role role,

            boolean emailVerified

    ) {}


    // Simple response
    public record MessageResponse(

            boolean success,

            String message

    ) {}

    // Google login
    public record GoogleLoginRequest(

            @NotBlank(message = "Google ID token is required")
            String idToken,

            Role role

    ) {}
}