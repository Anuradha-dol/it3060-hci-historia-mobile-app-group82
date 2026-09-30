package com.historia.backend.entity;

import com.historia.backend.enums.GuideApplicationStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "guide_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GuideProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    @OneToOne(optional = false)
    @JoinColumn(
            name = "user_id",
            nullable = false,
            unique = true
    )
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;


    @Column(nullable = false, length = 100)
    private String displayName;

    @Column(nullable = false, length = 100)
    private String primaryServiceArea;

    @ElementCollection
    @CollectionTable(
            name = "guide_service_areas",
            joinColumns = @JoinColumn(name = "guide_profile_id")
    )
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Column(name = "service_area", length = 100)
    @Builder.Default
    private Set<String> serviceAreas = new LinkedHashSet<>();

    @ElementCollection
    @CollectionTable(
            name = "guide_languages",
            joinColumns = @JoinColumn(name = "guide_profile_id")
    )
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Column(name = "language", length = 50)
    @Builder.Default
    private Set<String> languages = new LinkedHashSet<>();

    @Column(nullable = false)
    private Integer yearsExperience;

    @Column(length = 150)
    private String headline;

    @Column(length = 1500)
    private String bio;

    @ElementCollection
    @CollectionTable(
            name = "guide_specialties",
            joinColumns = @JoinColumn(name = "guide_profile_id")
    )
    @OnDelete(action = OnDeleteAction.CASCADE)
    @Column(name = "specialty", length = 100)
    @Builder.Default
    private Set<String> specialties = new LinkedHashSet<>();


    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private GuideApplicationStatus status =
            GuideApplicationStatus.PENDING;

    @Column(length = 1000)
    private String adminNote;

    private LocalDateTime submittedAt;

    private LocalDateTime reviewedAt;


    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;


    @PrePersist
    protected void onCreate() {

        LocalDateTime now = LocalDateTime.now();

        createdAt = now;
        updatedAt = now;

        if (submittedAt == null) {
            submittedAt = now;
        }

        if (status == null) {
            status = GuideApplicationStatus.PENDING;
        }

        if (serviceAreas == null) {
            serviceAreas = new LinkedHashSet<>();
        }

        if (languages == null) {
            languages = new LinkedHashSet<>();
        }

        if (specialties == null) {
            specialties = new LinkedHashSet<>();
        }
    }


    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
