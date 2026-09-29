package com.historia.backend.service;

import com.historia.backend.dto.UserDto;

public interface UserService {

    UserDto.UserProfileResponse getProfile(String username);

    UserDto.UserProfileResponse updateProfile(
            String username,
            UserDto.UpdateProfileRequest request
    );

    UserDto.MessageResponse changePassword(
            String username,
            UserDto.ChangePasswordRequest request
    );

    UserDto.MessageResponse logout(String username);

    UserDto.MessageResponse deleteAccount(
            String username,
            UserDto.DeleteAccountRequest request
    );
}