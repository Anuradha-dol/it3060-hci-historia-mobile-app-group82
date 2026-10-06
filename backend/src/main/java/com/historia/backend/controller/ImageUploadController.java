package com.historia.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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

    @PostMapping("/post-image")
    public ResponseEntity<Map<String, String>> uploadPostImage(
            @RequestParam("file") MultipartFile file
    ) throws IOException {

        return uploadImage(file, "posts");
    }

    @PostMapping("/place-image")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> uploadPlaceImage(
            @RequestParam("file") MultipartFile file
    ) throws IOException {

        return uploadImage(file, "places");
    }

    private ResponseEntity<Map<String, String>> uploadImage(
            MultipartFile file,
            String folder
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

        Path uploadRoot =
                resolveUploadRoot();

        Path uploadDirectory =
                uploadRoot
                        .resolve(folder)
                        .normalize();

        Files.createDirectories(uploadDirectory);

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
                uploadDirectory.resolve(fileName);

        Files.copy(
                file.getInputStream(),
                destination,
                StandardCopyOption.REPLACE_EXISTING
        );

        String imagePath =
                "/uploads/" + folder + "/" + fileName;

        String absoluteImageUrl =
                ServletUriComponentsBuilder
                        .fromCurrentContextPath()
                        .path(imagePath)
                        .toUriString();

        return ResponseEntity.ok(
                Map.of(
                        "imageUrl",
                        imagePath,
                        "absoluteImageUrl",
                        absoluteImageUrl
                )
        );
    }

    private Path resolveUploadRoot() {

        Path currentDirectory =
                Paths.get("")
                        .toAbsolutePath()
                        .normalize();

        Path currentUploads =
                currentDirectory
                        .resolve("uploads")
                        .normalize();

        Path parentUploads =
                currentDirectory
                        .resolve("..")
                        .resolve("uploads")
                        .normalize();

        Path directoryName =
                currentDirectory.getFileName();

        if (directoryName != null
                && "backend".equalsIgnoreCase(directoryName.toString())
                && Files.exists(parentUploads)) {

            return parentUploads;
        }

        return currentUploads;
    }
}
