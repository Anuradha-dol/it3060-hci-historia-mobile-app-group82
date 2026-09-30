package com.historia.backend.service.serviceImpl;

import com.historia.backend.dto.GuideDto;
import com.historia.backend.entity.GuideProfile;
import com.historia.backend.entity.User;
import com.historia.backend.enums.AuthProvider;
import com.historia.backend.enums.GuideApplicationStatus;
import com.historia.backend.enums.Role;
import com.historia.backend.exception.UserException;
import com.historia.backend.repository.GuideProfileRepository;
import com.historia.backend.repository.UserRepository;
import com.historia.backend.service.EmailService;
import com.historia.backend.service.GuideService;
import com.historia.backend.utils.OtpUtil;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
public class GuideServiceImpl implements GuideService {

    private final GuideProfileRepository guideProfileRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    public GuideServiceImpl(
            GuideProfileRepository guideProfileRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService
    ) {
        this.guideProfileRepository = guideProfileRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse registerGuide(
            GuideDto.GuideRegisterRequest request
    ) {

        String username = request.username().trim();
        String email = request.email().trim().toLowerCase();
        String phone = request.phone().trim();

        if (!request.password()
                .equals(request.confirmPassword())) {

            throw new UserException(
                    "Passwords do not match"
            );
        }

        if (userRepository
                .existsByUsernameIgnoreCaseAndDeletedFalse(username)) {

            throw new UserException(
                    "Username already exists"
            );
        }

        if (userRepository
                .existsByEmailIgnoreCaseAndDeletedFalse(email)) {

            throw new UserException(
                    "Email already exists"
            );
        }

        if (userRepository
                .existsByPhoneAndDeletedFalse(phone)) {

            throw new UserException(
                    "Phone number already exists"
            );
        }

        String otp = OtpUtil.generateOtp();
        LocalDateTime now = LocalDateTime.now();

        User user = User.builder()
                .username(username)
                .email(email)
                .phone(phone)
                .password(
                        passwordEncoder.encode(
                                request.password()
                        )
                )
                .firstName(clean(request.firstName()))
                .lastName(clean(request.lastName()))
                .address(clean(request.address()))
                .role(Role.GUIDE)
                .provider(AuthProvider.LOCAL)
                .emailVerified(false)
                .enabled(false)
                .deleted(false)
                .verifyCode(otp)
                .verifyCodeExpiry(
                        now.plusMinutes(5)
                )
                .lastOtpSentAt(now)
                .otpResendCount(0)
                .build();

        userRepository.save(user);

        String primaryArea =
                request.primaryServiceArea().trim();

        Set<String> serviceAreas =
                cleanSet(request.serviceAreas());

        serviceAreas.add(primaryArea);

        Set<String> languages =
                cleanSet(request.languages());

        if (languages.isEmpty()) {
            throw new UserException(
                    "At least one language is required"
            );
        }

        GuideProfile guideProfile =
                GuideProfile.builder()
                        .user(user)
                        .displayName(
                                request.displayName().trim()
                        )
                        .primaryServiceArea(primaryArea)
                        .serviceAreas(serviceAreas)
                        .languages(languages)
                        .yearsExperience(
                                request.yearsExperience()
                        )
                        .headline(
                                clean(request.headline())
                        )
                        .bio(
                                clean(request.bio())
                        )
                        .specialties(
                                cleanSet(
                                        request.specialties()
                                )
                        )
                        .status(
                                GuideApplicationStatus.PENDING
                        )
                        .submittedAt(now)
                        .build();

        guideProfileRepository.save(guideProfile);

        emailService.sendVerificationCode(
                user.getEmail(),
                otp
        );

        return toResponse(guideProfile);
    }


    @Override
    @Transactional(readOnly = true)
    public GuideDto.GuideProfileResponse getMyGuideProfile(
            String username
    ) {

        User user = getGuideUser(username);

        GuideProfile guideProfile =
                guideProfileRepository
                        .findByUser(user)
                        .orElseThrow(() ->
                                new UserException(
                                        "Guide profile not found"
                                )
                        );

        return toResponse(guideProfile);
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse updateMyGuideProfile(
            String username,
            GuideDto.UpdateGuideProfileRequest request
    ) {

        User user = getGuideUser(username);

        GuideProfile guideProfile =
                guideProfileRepository
                        .findByUser(user)
                        .orElseThrow(() ->
                                new UserException(
                                        "Guide profile not found"
                                )
                        );

        if (guideProfile.getStatus()
                == GuideApplicationStatus.REJECTED) {

            throw new UserException(
                    "Rejected guide applications cannot be updated"
            );
        }

        applyProfileUpdates(
                guideProfile,
                request.displayName(),
                request.primaryServiceArea(),
                request.serviceAreas(),
                request.languages(),
                request.yearsExperience(),
                request.headline(),
                request.bio(),
                request.specialties()
        );

        if (guideProfile.getStatus()
                == GuideApplicationStatus.NEEDS_WORK) {

            guideProfile.setStatus(
                    GuideApplicationStatus.PENDING
            );

            guideProfile.setSubmittedAt(
                    LocalDateTime.now()
            );

            guideProfile.setReviewedAt(null);

            user.setEnabled(false);
            user.setRefreshTokenHash(null);
            userRepository.save(user);
        }

        guideProfileRepository.save(guideProfile);

        return toResponse(guideProfile);
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse resubmitNeedsWorkApplication(
            GuideDto.GuideResubmitRequest request
    ) {

        String email =
                request.email().trim().toLowerCase();

        User user = userRepository
                .findByEmailIgnoreCaseAndDeletedFalse(email)
                .orElseThrow(() ->
                        new UserException(
                                "Invalid account details"
                        )
                );

        if (user.getRole() != Role.GUIDE) {
            throw new UserException(
                    "Guide account required"
            );
        }

        if (user.getProvider() != AuthProvider.LOCAL) {
            throw new UserException(
                    "Please use the guide registration flow for guide accounts"
            );
        }

        if (!user.isEmailVerified()) {
            throw new UserException(
                    "Please verify your email first"
            );
        }

        if (!passwordEncoder.matches(
                request.password(),
                user.getPassword()
        )) {

            throw new UserException(
                    "Invalid account details"
            );
        }

        GuideProfile guideProfile =
                guideProfileRepository
                        .findByUser(user)
                        .orElseThrow(() ->
                                new UserException(
                                        "Guide profile not found"
                                )
                        );

        if (guideProfile.getStatus()
                != GuideApplicationStatus.NEEDS_WORK) {

            throw new UserException(
                    "Only applications marked as needs work can be resubmitted"
            );
        }

        applyProfileUpdates(
                guideProfile,
                request.displayName(),
                request.primaryServiceArea(),
                request.serviceAreas(),
                request.languages(),
                request.yearsExperience(),
                request.headline(),
                request.bio(),
                request.specialties()
        );

        guideProfile.setStatus(
                GuideApplicationStatus.PENDING
        );

        guideProfile.setSubmittedAt(
                LocalDateTime.now()
        );

        guideProfile.setReviewedAt(null);

        user.setEnabled(false);
        user.setRefreshTokenHash(null);

        userRepository.save(user);
        guideProfileRepository.save(guideProfile);

        return toResponse(guideProfile);
    }


    @Override
    @Transactional(readOnly = true)
    public List<GuideDto.GuideProfileResponse> getGuidesByStatus(
            GuideApplicationStatus status
    ) {

        return guideProfileRepository
                .findByStatusAndUserDeletedFalse(status)
                .stream()
                .map(this::toResponse)
                .toList();
    }


    @Override
    @Transactional
    public GuideDto.GuideProfileResponse reviewGuide(
            Long guideProfileId,
            GuideDto.GuideReviewRequest request
    ) {

        GuideProfile guideProfile =
                guideProfileRepository
                        .findByIdAndUserDeletedFalse(guideProfileId)
                        .orElseThrow(() ->
                                new UserException(
                                        "Guide profile not found"
                                )
                        );

        GuideApplicationStatus status =
                request.status();

        if (status == GuideApplicationStatus.PENDING) {
            throw new UserException(
                    "Invalid review status"
            );
        }

        if ((status == GuideApplicationStatus.NEEDS_WORK ||
                status == GuideApplicationStatus.REJECTED)
                &&
                (request.adminNote() == null ||
                        request.adminNote()
                                .trim()
                                .isBlank())) {

            throw new UserException(
                    "Admin note is required for this status"
            );
        }

        User user = guideProfile.getUser();

        if (status == GuideApplicationStatus.APPROVED &&
                !user.isEmailVerified()) {

            throw new UserException(
                    "Guide email must be verified before approval"
            );
        }

        guideProfile.setStatus(status);

        guideProfile.setAdminNote(
                clean(request.adminNote())
        );

        guideProfile.setReviewedAt(
                LocalDateTime.now()
        );

        if (status == GuideApplicationStatus.APPROVED) {

            user.setEnabled(true);

        } else {

            user.setEnabled(false);
            user.setRefreshTokenHash(null);
        }

        userRepository.save(user);
        guideProfileRepository.save(guideProfile);

        return toResponse(guideProfile);
    }


    @Override
    @Transactional(readOnly = true)
    public List<GuideDto.GuideProfileResponse>
    getApprovedGuidesByArea(String area) {

        String searchArea = area.trim();

        if (searchArea.isBlank()) {
            throw new UserException(
                    "Service area is required"
            );
        }

        return guideProfileRepository
                .findByStatusAndUserDeletedFalse(
                        GuideApplicationStatus.APPROVED
                )
                .stream()
                .filter(profile ->
                        profile.getUser().isEnabled()
                )
                .filter(profile ->
                        matchesArea(
                                profile,
                                searchArea
                        )
                )
                .map(this::toResponse)
                .toList();
    }


    private User getGuideUser(String username) {

        User user = userRepository
                .findByUsernameIgnoreCaseAndDeletedFalse(
                        username
                )
                .orElseThrow(() ->
                        new UserException(
                                "User not found"
                        )
                );

        if (user.getRole() != Role.GUIDE) {
            throw new UserException(
                    "Guide account required"
            );
        }

        return user;
    }


    private boolean matchesArea(
            GuideProfile profile,
            String area
    ) {

        if (profile.getPrimaryServiceArea() != null &&
                profile.getPrimaryServiceArea()
                        .equalsIgnoreCase(area)) {

            return true;
        }

        if (profile.getServiceAreas() == null) {
            return false;
        }

        return profile.getServiceAreas()
                .stream()
                .anyMatch(serviceArea ->
                        serviceArea.equalsIgnoreCase(area)
                );
    }


    private void applyProfileUpdates(
            GuideProfile guideProfile,
            String displayName,
            String primaryServiceArea,
            Set<String> serviceAreas,
            Set<String> languages,
            Integer yearsExperience,
            String headline,
            String bio,
            Set<String> specialties
    ) {

        if (displayName != null) {

            if (displayName.trim().isBlank()) {
                throw new UserException(
                        "Display name cannot be empty"
                );
            }

            guideProfile.setDisplayName(
                    displayName.trim()
            );
        }

        if (primaryServiceArea != null) {

            if (primaryServiceArea.trim().isBlank()) {
                throw new UserException(
                        "Primary service area cannot be empty"
                );
            }

            guideProfile.setPrimaryServiceArea(
                    primaryServiceArea.trim()
            );
        }

        if (serviceAreas != null) {
            guideProfile.setServiceAreas(
                    cleanSet(serviceAreas)
            );
        }

        if (guideProfile.getServiceAreas() == null) {
            guideProfile.setServiceAreas(
                    new LinkedHashSet<>()
            );
        }

        guideProfile
                .getServiceAreas()
                .add(
                        guideProfile
                                .getPrimaryServiceArea()
                );

        if (languages != null) {

            Set<String> cleanedLanguages =
                    cleanSet(languages);

            if (cleanedLanguages.isEmpty()) {
                throw new UserException(
                        "At least one language is required"
                );
            }

            guideProfile.setLanguages(cleanedLanguages);
        }

        if (yearsExperience != null) {
            guideProfile.setYearsExperience(
                    yearsExperience
            );
        }

        if (headline != null) {
            guideProfile.setHeadline(
                    clean(headline)
            );
        }

        if (bio != null) {
            guideProfile.setBio(
                    clean(bio)
            );
        }

        if (specialties != null) {
            guideProfile.setSpecialties(
                    cleanSet(specialties)
            );
        }
    }


    private String clean(String value) {

        if (value == null) {
            return null;
        }

        String cleaned = value.trim();

        return cleaned.isBlank()
                ? null
                : cleaned;
    }


    private Set<String> cleanSet(
            Set<String> values
    ) {

        Set<String> cleaned =
                new LinkedHashSet<>();

        if (values == null) {
            return cleaned;
        }

        for (String value : values) {

            String item = clean(value);

            if (item != null) {
                cleaned.add(item);
            }
        }

        return cleaned;
    }


    private Set<String> copySet(Set<String> values) {

        if (values == null) {
            return new LinkedHashSet<>();
        }

        return new LinkedHashSet<>(values);
    }


    private GuideDto.GuideProfileResponse toResponse(
            GuideProfile profile
    ) {

        User user = profile.getUser();

        return new GuideDto.GuideProfileResponse(
                profile.getId(),
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getPhone(),
                user.getFirstName(),
                user.getLastName(),
                user.getAddress(),
                profile.getDisplayName(),
                profile.getPrimaryServiceArea(),
                copySet(profile.getServiceAreas()),
                copySet(profile.getLanguages()),
                profile.getYearsExperience(),
                profile.getHeadline(),
                profile.getBio(),
                copySet(profile.getSpecialties()),
                profile.getStatus(),
                profile.getAdminNote(),
                profile.getSubmittedAt(),
                profile.getReviewedAt(),
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }
}
