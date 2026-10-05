package com.historia.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/uploads")
public class ImageUploadController {

    private static final Path UPLOAD_DIRECTORY =
            Paths.get("uploads", "posts")
                    .toAbsolutePath()
                    .normalize();

    @PostMapping("/post-image")
    public ResponseEntity<Map<String, String>> uploadPostImage(
            @RequestParam("file") MultipartFile file
    ) throws IOException {

        if (file.isEmpty()) {
            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            "Please select an image."
                    ));
        }

        String contentType = file.getContentType();

        if (contentType == null ||
                !contentType.startsWith("image/")) {

            return ResponseEntity
                    .badRequest()
                    .body(Map.of(
                            "message",
                            "Only image files are allowed."
                    ));
        }

        Files.createDirectories(UPLOAD_DIRECTORY);

        String originalFilename =
                file.getOriginalFilename();

        String extension = "";

        if (originalFilename != null &&
                originalFilename.contains(".")) {

            extension = originalFilename.substring(
                    originalFilename.lastIndexOf(".")
            );
        }

        String fileName =
                UUID.randomUUID() + extension;

        Path destination =
                UPLOAD_DIRECTORY.resolve(fileName);

        Files.copy(
                file.getInputStream(),
                destination,
                StandardCopyOption.REPLACE_EXISTING
        );

        String imageUrl =
                ServletUriComponentsBuilder
                        .fromCurrentContextPath()
                        .path("/uploads/posts/")
                        .path(fileName)
                        .toUriString();

        return ResponseEntity.ok(
                Map.of(
                        "imageUrl",
                        imageUrl
                )
        );
    }
}