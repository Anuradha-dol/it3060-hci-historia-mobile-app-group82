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


    // View profile
    @Override
    public UserDto.UserProfileResponse getProfile(String username) {

        User user = getUser(username);

        return toProfileResponse(user);
    }


    // Update profile
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


    // Change password
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

        // End old refresh sessions
        user.setRefreshTokenHash(null);

        userRepository.save(user);

        return new UserDto.MessageResponse(
                true,
                "Password changed successfully"
        );
    }


    // Logout
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


    // Delete account
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

        // Remove temporary reset data
        forgotPasswordRepository.deleteByUser(user);

        // Remove personal data
        user.setFirstName(null);
        user.setLastName(null);
        user.setAddress(null);

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

        // Clear login data
        user.setPassword(
                passwordEncoder.encode(
                        UUID.randomUUID().toString()
                )
        );

        user.setRefreshTokenHash(null);

        // Clear OTP data
        user.setVerifyCode(null);
        user.setVerifyCodeExpiry(null);
        user.setLastOtpSentAt(null);
        user.setOtpResendCount(0);
        user.setOtpFirstResendTime(null);
        user.setOtpBlockUntil(null);

        // Disable account
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


    // Find user
    private User getUser(String username) {

        return userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(username)
                .orElseThrow(() ->
                        new UserException("User not found")
                );
    }


    // Profile response
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
                user.getRole(),
                user.isEmailVerified()
        );
    }
}