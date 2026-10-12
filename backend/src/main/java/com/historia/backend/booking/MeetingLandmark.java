package com.historia.backend.booking;
import jakarta.persistence.*;
import lombok.*;
@Entity @Getter @Setter @NoArgsConstructor
@Table(name = "guide_meeting_landmarks")
public class MeetingLandmark {
    @Id private String id;
    private String name;
    private String area;
    private String description;
    private String accessInfo;
    // Schematic positions only, never GPS coordinates.
    private double mapX;
    private double mapY;
}
