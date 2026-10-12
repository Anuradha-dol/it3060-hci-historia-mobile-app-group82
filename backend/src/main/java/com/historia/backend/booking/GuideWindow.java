package com.historia.backend.booking;
import com.historia.backend.entity.GuideProfile;
import jakarta.persistence.*;
import lombok.*;
import java.time.Instant;
@Entity @Getter @Setter @NoArgsConstructor
@Table(name = "guide_booking_windows")
public class GuideWindow {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) private GuideProfile guide;
    @Column(nullable = false) private Instant startsAt;
    @Column(nullable = false) private Instant endsAt;
}
