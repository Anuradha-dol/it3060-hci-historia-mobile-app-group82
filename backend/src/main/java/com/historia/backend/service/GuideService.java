package com.historia.backend.service;

import com.historia.backend.dto.GuideDto;
import com.historia.backend.enums.GuideApplicationStatus;

import java.util.List;

public interface GuideService {

    GuideDto.GuideProfileResponse registerGuide(
            GuideDto.GuideRegisterRequest request
    );

    GuideDto.GuideProfileResponse getMyGuideProfile(
            String username
    );

    GuideDto.GuideProfileResponse updateMyGuideProfile(
            String username,
            GuideDto.UpdateGuideProfileRequest request
    );

    GuideDto.GuideProfileResponse resubmitNeedsWorkApplication(
            GuideDto.GuideResubmitRequest request
    );

    List<GuideDto.GuideProfileResponse> getGuidesByStatus(
            GuideApplicationStatus status
    );

    GuideDto.GuideProfileResponse reviewGuide(
            Long guideProfileId,
            GuideDto.GuideReviewRequest request
    );

    List<GuideDto.GuideProfileResponse> getApprovedGuidesByArea(
            String area
    );
}
