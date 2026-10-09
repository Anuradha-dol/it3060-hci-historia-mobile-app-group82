package com.historia.backend.config;

import com.historia.backend.security.JwtAuthFilter;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                // Disable CSRF because JWT is used
                .csrf(csrf -> csrf.disable())

                // Stateless authentication
                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .authorizeHttpRequests(auth -> auth

                        // -----------------------------
                        // AUTH
                        // -----------------------------
                        .requestMatchers(
                                "/api/auth/**"
                        )
                        .permitAll()

                        .requestMatchers(
                                "/ws/**"
                        )
                        .permitAll()

                        // -----------------------------
                        // UPLOADED IMAGES
                        // -----------------------------
                        .requestMatchers(
                                HttpMethod.GET,
                                "/uploads/**"
                        )
                        .permitAll()

                        // -----------------------------
                        // GUIDE REGISTRATION
                        // -----------------------------
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/guides/register"
                        )
                        .permitAll()

                        // -----------------------------
                        // GUIDE RESUBMISSION
                        // -----------------------------
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/guides/resubmit"
                        )
                        .permitAll()

                        // -----------------------------
                        // APPROVED GUIDES
                        // -----------------------------
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/guides/approved"
                        )
                        .permitAll()

                        // -----------------------------
                        // EVERYTHING ELSE
                        // JWT REQUIRED
                        // -----------------------------
                        .anyRequest()
                        .authenticated()
                )

                // Disable default login page
                .formLogin(form ->
                        form.disable()
                )

                // Disable HTTP Basic authentication
                .httpBasic(basic ->
                        basic.disable()
                )

                // JWT filter
                .addFilterBefore(
                        jwtAuthFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}
