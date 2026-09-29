package com.historia.backend.service.serviceImpl;

import com.historia.backend.service.EmailService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailServiceImpl implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailServiceImpl(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    public void sendVerificationCode(String email, String code) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Verify Your Email");
        message.setText(
                "Your HISTORIA verification code is: " + code +
                        "\n\nThis code will expire in 5 minutes."
        );

        mailSender.send(message);
    }

    @Override
    public void sendPasswordResetCode(String email, String code) {

        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("HISTORIA - Password Reset");
        message.setText(
                "Your HISTORIA password reset code is: " + code +
                        "\n\nThis code will expire in 5 minutes."
        );

        mailSender.send(message);
    }
}