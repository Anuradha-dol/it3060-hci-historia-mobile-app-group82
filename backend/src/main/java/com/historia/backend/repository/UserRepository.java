package com.historia.backend.repository;

import com.historia.backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailIgnoreCaseAndDeletedFalse(String email);

    Optional<User> findByUsernameIgnoreCaseAndDeletedFalse(String username);

    Optional<User> findByPhoneAndDeletedFalse(String phone);

    Optional<User> findByIdAndDeletedFalse(Long id);

    boolean existsByEmailIgnoreCaseAndDeletedFalse(String email);

    boolean existsByUsernameIgnoreCaseAndDeletedFalse(String username);

    boolean existsByPhoneAndDeletedFalse(String phone);
}