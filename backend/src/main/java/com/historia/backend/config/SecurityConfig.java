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
                .csrf(csrf -> csrf.disable())

                // No server session
                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .authorizeHttpRequests(auth -> auth

                        // Public authentication endpoints
                        .requestMatchers(
                                "/api/auth/**"
                        )
                        .permitAll()

                        // Public guide registration
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/guides/register"
                        )
                        .permitAll()

                        // Public guide application resubmit before approval
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/guides/resubmit"
                        )
                        .permitAll()

                        // Public approved guide search
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/guides/approved"
                        )
                        .permitAll()

                        // All other endpoints need login
                        .anyRequest()
                        .authenticated()
                )

                .formLogin(form ->
                        form.disable()
                )

                .httpBasic(basic ->
                        basic.disable()
                )

                .addFilterBefore(
                        jwtAuthFilter,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}
