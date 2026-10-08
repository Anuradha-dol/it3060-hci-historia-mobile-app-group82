package com.historia.backend.booking;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

public final class BookingDto {
    private BookingDto() {}
    public record PackageView(Long id, String name, String features, int durationMinutes,
        BigDecimal pricePerVisitor, int minVisitors, int maxVisitors, boolean enabled) {}
    public record GuideView(Long id, String name, Set<String> languages, Set<String> specialties,
        Set<String> serviceAreas, int yearsExperience, String imageUrl, boolean certified,
        boolean demo, Double rating, Integer reviewCount, List<PackageView> packages, boolean available) {}
    public record PackageInput(Long id, @NotBlank @Size(max=100) String name,
        @Size(max=250) String features, @Min(15) @Max(480) int durationMinutes,
        @NotNull @DecimalMin("1.00") @DecimalMax("1000000") @Digits(integer=7,fraction=2) BigDecimal pricePerVisitor,
        @Min(1) @Max(100) int minVisitors, @Min(1) @Max(100) int maxVisitors, boolean enabled) {}
    public record WindowInput(@NotNull Instant startsAt, @NotNull Instant endsAt) {}
    public record HoldInput(@NotNull Long guideId, @NotNull Long packageId,
        @NotBlank String landmarkId, @NotNull Instant startsAt, @Min(1) @Max(100) int visitors,
        @NotBlank @Size(max=80) String requestKey) {}
    public record StateInput(@NotBlank String state) {}
    public record PaymentInput(@NotBlank String outcome) {}
    public record PinInput(@Pattern(regexp="[0-9]{4}") @NotNull String pin) {}
    public record LocationInput(@NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
        @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude, Instant eta) {}
    public record Checkout(String bookingId, String reference, BigDecimal amount, String currency,
        String guide, String packageName, MeetingLandmark meetingPoint, Instant startsAt,
        int visitors, Instant expiresAt, boolean demoEnabled) {}
    public record BookingView(String id, String reference, Long guideId, String guideName, String guidePhone,
        String participantPhone, String packageName, MeetingLandmark landmark, Instant startsAt, Instant endsAt,
        int visitors, BigDecimal amount, String currency, String state, String paymentState, Instant holdExpiresAt,
        String meetingPin, Instant pinExpiresAt, boolean pinUsed, int pinAttemptsRemaining,
        Double latitude, Double longitude, Instant locationUpdatedAt, Instant eta, boolean demoPaymentEnabled) {}
}
