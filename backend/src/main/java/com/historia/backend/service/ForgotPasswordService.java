package com.historia.backend.service;

import com.historia.backend.dto.UserDto;

public interface ForgotPasswordService {

    UserDto.MessageResponse requestReset(
            UserDto.ForgotPasswordRequest request
    );

    UserDto.MessageResponse verifyOtp(
            UserDto.ForgotPasswordVerifyRequest request
    );

    UserDto.MessageResponse resendOtp(
            UserDto.ForgotPasswordResendRequest request
    );

    UserDto.MessageResponse resetPassword(
            UserDto.ResetPasswordRequest request
    );
}