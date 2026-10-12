package com.historia.backend.booking;
import com.historia.backend.entity.*;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.Instant;
@Entity @Getter @Setter @NoArgsConstructor
@Table(name = "guide_bookings", uniqueConstraints = @UniqueConstraint(columnNames = {"tourist_id", "request_key"}),
 indexes = @Index(columnList = "guide_id,startsAt,endsAt"))
public class GuideBooking {
    @Id private String id;
    @ManyToOne(optional = false) private User tourist;
    @ManyToOne(optional = false) private GuideProfile guide;
    @ManyToOne(optional = false) private GuidePackage tourPackage;
    @ManyToOne(optional = false) private MeetingLandmark landmark;
    @Column(name = "request_key", nullable = false, length = 80) private String requestKey;
    private Instant startsAt;
    private Instant endsAt;
    private Instant holdExpiresAt;
    private int visitors;
    private String packageName;
    @Column(precision = 12, scale = 2) private BigDecimal amount;
    private String state = "HELD";
    private String paymentState = "UNPAID";
    @Column(unique = true) private String paymentReference;
    private String meetingPin;
    private Instant pinExpiresAt;
    private int pinAttempts;
    private Instant pinUsedAt;
    private Double latitude;
    private Double longitude;
    private Instant locationUpdatedAt;
    private Instant eta;
}
