package com.historia.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.historia.backend.enums.AuthProvider;
import com.historia.backend.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;


    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(nullable = false, unique = true, length = 150)
    private String email;

    @Column(unique = true, length = 20)
    private String phone;

    @Column(nullable = false)
    @JsonIgnore
    private String password;

    @Column(length = 100)
    private String firstName;

    @Column(length = 100)
    private String lastName;

    @Column(length = 500)
    private String address;

    @Column(length = 500)
    private String profileImageUrl;

    @Column(length = 500)
    private String coverImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;


    private String verifyCode;

    private LocalDateTime verifyCodeExpiry;

    @Builder.Default
    @Column(nullable = false)
    private boolean emailVerified = false;

    private LocalDateTime lastOtpSentAt;

    @Builder.Default
    private Integer otpResendCount = 0;

    private LocalDateTime otpFirstResendTime;

    private LocalDateTime otpBlockUntil;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    @Builder.Default
    private AuthProvider provider = AuthProvider.LOCAL;

    @Column(length = 150)
    private String providerId;

    @Column(length = 64)
    @JsonIgnore
    private String refreshTokenHash;

    @OneToOne(
            mappedBy = "user",
            cascade = CascadeType.ALL,
            orphanRemoval = true,
            fetch = FetchType.LAZY
    )
    @JsonIgnore
    private GuideProfile guideProfile;

    @OneToOne(
            mappedBy = "user",
            cascade = CascadeType.ALL,
            orphanRemoval = true,
            fetch = FetchType.LAZY
    )
    @JsonIgnore
    private ForgotPassword forgotPassword;

    @Builder.Default
    @Column(nullable = false)
    private boolean enabled = true;

    @Builder.Default
    @Column(nullable = false)
    private boolean deleted = false;

    private LocalDateTime deletedAt;




    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {

        LocalDateTime now = LocalDateTime.now();

        createdAt = now;
        updatedAt = now;

        if (provider == null) {
            provider = AuthProvider.LOCAL;
        }

        if (otpResendCount == null) {
            otpResendCount = 0;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }


    @Override
    @JsonIgnore
    public String getUsername() {
        return username;
    }

    @Override
    @JsonIgnore
    public String getPassword() {
        return password;
    }

    @Override
    @JsonIgnore
    public Collection<? extends GrantedAuthority> getAuthorities() {

        return List.of(
                new SimpleGrantedAuthority("ROLE_" + role.name())
        );
    }

    @Override
    @JsonIgnore
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    @JsonIgnore
    public boolean isAccountNonLocked() {
        return !deleted;
    }

    @Override
    @JsonIgnore
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    @JsonIgnore
    public boolean isEnabled() {
        return enabled && emailVerified && !deleted;
    }
}
