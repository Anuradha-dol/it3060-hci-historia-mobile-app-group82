package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.UserDto;
import com.historia.backend.entity.User;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.ForgotPasswordRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.UserService;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final ForgotPasswordRepository forgotPasswordRepository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(
            UserRepository userRepository,
            ForgotPasswordRepository forgotPasswordRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.forgotPasswordRepository = forgotPasswordRepository;
        this.passwordEncoder = passwordEncoder;
    }


    @Override
    public UserDto.UserProfileResponse getProfile(String username) {

        User user = getUser(username);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.UserProfileResponse updateProfile(
            String username,
            UserDto.UpdateProfileRequest request
    ) {

        User user = getUser(username);

        if (request.firstName() != null) {
            user.setFirstName(request.firstName().trim());
        }

        if (request.lastName() != null) {
            user.setLastName(request.lastName().trim());
        }

        if (request.address() != null) {
            user.setAddress(request.address().trim());
        }

        if (request.profileImageUrl() != null) {
            user.setProfileImageUrl(cleanNullable(request.profileImageUrl()));
        }

        if (request.coverImageUrl() != null) {
            user.setCoverImageUrl(cleanNullable(request.coverImageUrl()));
        }

        if (request.phone() != null) {

            String phone = request.phone().trim();

            if (phone.isBlank()) {
                throw new UserException(
                        "Phone number cannot be empty"
                );
            }

            if (!phone.equals(user.getPhone()) &&
                    userRepository.existsByPhoneAndDeletedFalse(phone)) {

                throw new UserException(
                        "Phone number already exists"
                );
            }

            user.setPhone(phone);
        }

        userRepository.save(user);

        return toProfileResponse(user);
    }


    @Override
    @Transactional
    public UserDto.MessageResponse changePassword(
            String username,
            UserDto.ChangePasswordRequest request
    ) {

        User user = getUser(username);

        if (!passwordEncoder.matches(
                request.currentPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Current password is incorrect"
            );
        }

        if (!request.newPassword()
                .equals(request.confirmPassword())) {

            throw new UserException(
                    "Passwords do not match"
            );
        }

        if (passwordEncoder.matches(
                request.newPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "New password must be different from the current password"
            );
        }

        user.setPassword(
                passwordEncoder.encode(
                        request.newPassword()
                )
        );

        user.setRefreshTokenHash(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Password changed successfully"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse logout(String username) {

        User user = getUser(username);

        user.setRefreshTokenHash(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Logged out successfully"
        );
    }


    @Override
    @Transactional
    public UserDto.MessageResponse deleteAccount(
            String username,
            UserDto.DeleteAccountRequest request
    ) {

        User user = getUser(username);

        if (!passwordEncoder.matches(
                request.currentPassword(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Current password is incorrect"
            );
        }

        Long userId = user.getId();

        forgotPasswordRepository.deleteByUserId(userId);

        user.setFirstName(null);
        user.setLastName(null);
        user.setAddress(null);
        user.setProfileImageUrl(null);
        user.setCoverImageUrl(null);

        user.setUsername(
                "deleted_" + userId
        );

        user.setEmail(
                "deleted_" + userId + "@historia.local"
        );

        user.setPhone(
                "deleted_" + userId
        );

        user.setProviderId(null);

        user.setPassword(
                passwordEncoder.encode(
                        UUID.randomUUID().toString()
                )
        );

        user.setRefreshTokenHash(null);

        user.setVerifyCode(null);
        user.setVerifyCodeExpiry(null);
        user.setLastOtpSentAt(null);
        user.setOtpResendCount(0);
        user.setOtpFirstResendTime(null);
        user.setOtpBlockUntil(null);

        user.setEmailVerified(false);
        user.setEnabled(false);
        user.setDeleted(true);
        user.setDeletedAt(LocalDateTime.now());

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Account deleted successfully"
        );
    }


    private User getUser(String username) {

        return userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }


    private UserDto.UserProfileResponse toProfileResponse(
            User user
    ) {

        return new UserDto.UserProfileResponse(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getPhone(),
                user.getFirstName(),
                user.getLastName(),
                user.getAddress(),
                user.getProfileImageUrl(),
                user.getCoverImageUrl(),
                user.getRole(),
                user.isEmailVerified()
        );
    }


    private String cleanNullable(String value) {

        String cleaned = value.trim();

        return cleaned.isBlank()
                ? null
                : cleaned;
    }
}
