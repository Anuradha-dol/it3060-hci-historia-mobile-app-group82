package com.historia.backend.repository;

import com.historia.backend.entity.ForgotPassword;
import com.historia.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ForgotPasswordRepository
        extends JpaRepository<ForgotPassword, Long> {

    Optional<ForgotPassword> findByUser(User user);

    void deleteByUser(User user);

    void deleteByUserId(Long userId);
}
