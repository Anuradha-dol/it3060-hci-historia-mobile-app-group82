package com.historia.backend.dto;

import com.historia.backend.enums.GuideApplicationStatus;
import jakarta.validation.constraints.*;

import java.time.LocalDateTime;
import java.util.Set;

public class GuideDto {


    public record GuideRegisterRequest(

            @NotBlank(message = "Username is required")
            String username,

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Phone number is required")
            String phone,

            @NotBlank(message = "Password is required")
            @Size(
                    min = 8,
                    message = "Password must be at least 8 characters"
            )
            String password,

            @NotBlank(message = "Confirm password is required")
            String confirmPassword,

            String firstName,

            String lastName,

            String address,


            @NotBlank(message = "Display name is required")
            @Size(max = 100)
            String displayName,

            @NotBlank(message = "Primary service area is required")
            @Size(max = 100)
            String primaryServiceArea,

            Set<String> serviceAreas,

            @NotEmpty(message = "At least one language is required")
            Set<String> languages,

            @NotNull(message = "Years of experience is required")
            @Min(
                    value = 0,
                    message = "Years of experience cannot be negative"
            )
            @Max(
                    value = 60,
                    message = "Please provide valid years of experience"
            )
            Integer yearsExperience,

            @Size(max = 150)
            String headline,

            @Size(max = 1500)
            String bio,

            Set<String> specialties

    ) {
    }


    public record UpdateGuideProfileRequest(

            @Size(max = 100)
            String displayName,

            @Size(max = 100)
            String primaryServiceArea,

            Set<String> serviceAreas,

            Set<String> languages,

            @Min(
                    value = 0,
                    message = "Years of experience cannot be negative"
            )
            @Max(
                    value = 60,
                    message = "Please provide valid years of experience"
            )
            Integer yearsExperience,

            @Size(max = 150)
            String headline,

            @Size(max = 1500)
            String bio,

            Set<String> specialties

    ) {
    }


    public record GuideResubmitRequest(

            @NotBlank(message = "Email is required")
            @Email(message = "Please provide a valid email")
            String email,

            @NotBlank(message = "Password is required")
            String password,

            @Size(max = 100)
            String displayName,

            @Size(max = 100)
            String primaryServiceArea,

            Set<String> serviceAreas,

            Set<String> languages,

            @Min(
                    value = 0,
                    message = "Years of experience cannot be negative"
            )
            @Max(
                    value = 60,
                    message = "Please provide valid years of experience"
            )
            Integer yearsExperience,

            @Size(max = 150)
            String headline,

            @Size(max = 1500)
            String bio,

            Set<String> specialties

    ) {
    }


    public record GuideReviewRequest(

            @NotNull(message = "Guide status is required")
            GuideApplicationStatus status,

            @Size(max = 1000)
            String adminNote

    ) {
    }


    public record GuideProfileResponse(

            Long id,

            Long userId,

            String username,

            String email,

            String phone,

            String firstName,

            String lastName,

            String address,

            String displayName,

            String primaryServiceArea,

            Set<String> serviceAreas,

            Set<String> languages,

            Integer yearsExperience,

            String headline,

            String bio,

            Set<String> specialties,

            GuideApplicationStatus status,

            String adminNote,

            LocalDateTime submittedAt,

            LocalDateTime reviewedAt,

            LocalDateTime createdAt,

            LocalDateTime updatedAt

    ) {
    }
}
