package com.historia.backend.booking;

import com.historia.backend.entity.GuideProfile;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity @Getter @Setter @NoArgsConstructor
@Table(name = "guide_booking_packages")
public class GuidePackage {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(optional = false) private GuideProfile guide;
    @Column(nullable = false) private String name;
    private String features;
    private int durationMinutes;
    @Column(precision = 12, scale = 2, nullable = false) private BigDecimal pricePerVisitor;
    private int minVisitors = 1;
    private int maxVisitors = 10;
    private boolean enabled = true;
}
