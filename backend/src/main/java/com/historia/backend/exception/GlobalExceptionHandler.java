package com.historia.backend.exception;

import com.historia.backend.dto.UserDto;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
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