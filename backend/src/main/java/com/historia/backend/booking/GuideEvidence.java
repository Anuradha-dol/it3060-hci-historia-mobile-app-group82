package com.historia.backend.booking;
import com.historia.backend.entity.GuideProfile;
import jakarta.persistence.*;
import lombok.*;
@Entity @Getter @Setter @NoArgsConstructor
@Table(name = "guide_booking_evidence")
public class GuideEvidence {
    @Id private Long id;
    @OneToOne @MapsId private GuideProfile guide;
    private boolean certified;
    private boolean demo;
    private Double rating;
    private Integer reviewCount;
}
