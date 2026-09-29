package com.historia.backend.service;

import com.historia.backend.dto.UserDto;

public interface AuthService {

    UserDto.MessageResponse register(
            UserDto.RegisterRequest request
    );

    UserDto.MessageResponse verifyEmail(
            UserDto.VerifyOtpRequest request
    );

    UserDto.MessageResponse resendOtp(
            UserDto.ResendOtpRequest request
    );

    UserDto.AuthResponse login(
            UserDto.LoginRequest request
    );

    UserDto.AuthResponse refreshToken(
            UserDto.RefreshTokenRequest request
    );

    UserDto.AuthResponse googleLogin(
            UserDto.GoogleLoginRequest request
    );
}