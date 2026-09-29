package com.historia.backend.service;

public interface EmailService {

    void sendVerificationCode(String email, String code);

    void sendPasswordResetCode(String email, String code);
}