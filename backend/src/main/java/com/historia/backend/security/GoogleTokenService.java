package com.historia.backend.security;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.historia.backend.exception.UserException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;

@Service
public class GoogleTokenService {

    private final GoogleIdTokenVerifier verifier;

    public GoogleTokenService(
            @Value("${spring.security.oauth2.client.registration.google.client-id}")
            String clientId
    ) {

        try {
            this.verifier = new GoogleIdTokenVerifier.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(),
                    GsonFactory.getDefaultInstance()
            )
                    .setAudience(
                            Collections.singletonList(clientId)
                    )
                    .build();

        } catch (GeneralSecurityException | IOException exception) {
            throw new IllegalStateException(
                    "Could not initialize Google login",
                    exception
            );
        }
    }


    // Verify Google token
    public GoogleUserInfo verify(String token) {

        try {
            GoogleIdToken idToken = verifier.verify(token);

            if (idToken == null) {
                throw new UserException(
                        "Invalid Google account"
                );
            }

            GoogleIdToken.Payload payload =
                    idToken.getPayload();

            if (!Boolean.TRUE.equals(
                    payload.getEmailVerified()
            )) {
                throw new UserException(
                        "Google email is not verified"
                );
            }

            String firstName =
                    payload.get("given_name") == null
                            ? null
                            : payload.get("given_name").toString();

            String lastName =
                    payload.get("family_name") == null
                            ? null
                            : payload.get("family_name").toString();

            return new GoogleUserInfo(
                    payload.getSubject(),
                    payload.getEmail(),
                    firstName,
                    lastName
            );

        } catch (GeneralSecurityException | IOException exception) {

            throw new UserException(
                    "Invalid Google account"
            );
        }
    }


    public record GoogleUserInfo(
            String providerId,
            String email,
            String firstName,
            String lastName
    ) {}
}