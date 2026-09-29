package com.historia.backend.controller;

import com.historia.backend.dto.GuideDto;
import com.historia.backend.service.GuideService;
import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/guides")
public class GuideController {

    private final GuideService guideService;

    public GuideController(GuideService guideService) {
        this.guideService = guideService;
    }


    // Guide registration
    @PostMapping("/register")
    public ResponseEntity<GuideDto.GuideProfileResponse> registerGuide(
            @Valid @RequestBody GuideDto.GuideRegisterRequest request
    ) {

        return ResponseEntity.ok(
                guideService.registerGuide(request)
        );
    }


    // Resubmit guide application after admin requests changes
    @PostMapping("/resubmit")
    public ResponseEntity<GuideDto.GuideProfileResponse> resubmitGuide(
            @Valid @RequestBody GuideDto.GuideResubmitRequest request
    ) {

        return ResponseEntity.ok(
                guideService.resubmitNeedsWorkApplication(request)
        );
    }


    // My guide profile
    @GetMapping("/me")
    @PreAuthorize("hasRole('GUIDE')")
    public ResponseEntity<GuideDto.GuideProfileResponse> getMyGuideProfile(
            Authentication authentication
    ) {

        return ResponseEntity.ok(
                guideService.getMyGuideProfile(
                        authentication.getName()
                )
        );
    }


    // Update guide profile
    @PutMapping("/me")
    @PreAuthorize("hasRole('GUIDE')")
    public ResponseEntity<GuideDto.GuideProfileResponse> updateMyGuideProfile(
            Authentication authentication,
            @Valid @RequestBody GuideDto.UpdateGuideProfileRequest request
    ) {

        return ResponseEntity.ok(
                guideService.updateMyGuideProfile(
                        authentication.getName(),
                        request
                )
        );
    }


    // Approved guides by area
    @GetMapping("/approved")
    public ResponseEntity<List<GuideDto.GuideProfileResponse>>
    getApprovedGuidesByArea(
            @RequestParam String area
    ) {

        return ResponseEntity.ok(
                guideService.getApprovedGuidesByArea(area)
        );
    }
}
