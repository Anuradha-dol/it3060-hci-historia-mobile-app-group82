package com.historia.backend.entity;

import com.historia.backend.enums.Role;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "notifications",
        indexes = {
                @Index(name = "idx_notifications_recipient_created", columnList = "recipient_id, created_at"),
                @Index(name = "idx_notifications_recipient_read", columnList = "recipient_id, read_flag")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AppNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_role", nullable = false, length = 20)
    private Role recipientRole;

    @Column(nullable = false, length = 40)
    private String type;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, length = 600)
    private String message;

    @Column(name = "reference_type", length = 60)
    private String referenceType;

    @Column(name = "reference_id", length = 100)
    private String referenceId;

    @Column(name = "action_route", length = 140)
    private String actionRoute;

    @Builder.Default
    @Column(name = "read_flag", nullable = false)
    private boolean read = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();

        if (recipientRole == null && recipient != null) {
            recipientRole = recipient.getRole();
        }
    }
}
