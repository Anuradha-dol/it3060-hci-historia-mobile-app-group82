package com.historia.backend.exception;

import com.historia.backend.dto.UserDto;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // User errors
    @ExceptionHandler(UserException.class)
    public ResponseEntity<UserDto.MessageResponse> handleUserException(
            UserException exception
    ) {

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        exception.getMessage()
                ));
    }

    // Missing or invalid authentication
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<UserDto.MessageResponse> handleAuthenticationException(
            AuthenticationException exception
    ) {

        return ResponseEntity
                .status(HttpStatus.UNAUTHORIZED)
                .body(new UserDto.MessageResponse(
                        false,
                        "Authentication required"
                ));
    }


    // Role or permission errors
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<UserDto.MessageResponse> handleAccessDeniedException(
            AccessDeniedException exception
    ) {

        return ResponseEntity
                .status(HttpStatus.FORBIDDEN)
                .body(new UserDto.MessageResponse(
                        false,
                        "Access denied"
                ));
    }


    // Validation errors
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<UserDto.MessageResponse> handleValidationException(
            MethodArgumentNotValidException exception
    ) {

        String message = exception
                .getBindingResult()
                .getFieldErrors()
                .stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .orElse("Invalid request");

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        message
                ));
    }


    // Invalid query or path parameter values
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<UserDto.MessageResponse> handleTypeMismatchException(
            MethodArgumentTypeMismatchException exception
    ) {

        return ResponseEntity
                .badRequest()
                .body(new UserDto.MessageResponse(
                        false,
                        "Invalid request parameter"
                ));
    }


    // Other errors
    @ExceptionHandler(Exception.class)
    public ResponseEntity<UserDto.MessageResponse> handleException(
            Exception exception
    ) {

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new UserDto.MessageResponse(
                        false,
                        "Something went wrong"
                ));
    }
}
