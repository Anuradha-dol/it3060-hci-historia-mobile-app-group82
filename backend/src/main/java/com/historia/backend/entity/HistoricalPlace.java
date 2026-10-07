package com.historia.backend.entity;

import jakarta.persistence.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "historical_places")
public class HistoricalPlace {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String subtitle;

    private String location;

    @Column(length = 3000)
    private String description;

    private Double rating;

    private Integer reviewCount;

    private Double entranceFee;

    private String openingHours;

    private Double latitude;

    private Double longitude;

    private String mainImageUrl;

    @Transient
    private Long tourCount = 0L;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
            name = "historical_place_gallery",
            joinColumns = @JoinColumn(name = "historical_place_id")
    )
    @Column(name = "image_url")
    private List<String> galleryImages = new ArrayList<>();

    public HistoricalPlace() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getSubtitle() {
        return subtitle;
    }

    public void setSubtitle(String subtitle) {
        this.subtitle = subtitle;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getRating() {
        return rating;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public Integer getReviewCount() {
        return reviewCount;
    }

    public void setReviewCount(Integer reviewCount) {
        this.reviewCount = reviewCount;
    }

    public Double getEntranceFee() {
        return entranceFee;
    }

    public void setEntranceFee(Double entranceFee) {
        this.entranceFee = entranceFee;
    }

    public String getOpeningHours() {
        return openingHours;
    }

    public void setOpeningHours(String openingHours) {
        this.openingHours = openingHours;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public String getMainImageUrl() {
        return mainImageUrl;
    }

    public void setMainImageUrl(String mainImageUrl) {
        this.mainImageUrl = mainImageUrl;
    }

    public Long getTourCount() {
        return tourCount;
    }

    public void setTourCount(Long tourCount) {
        this.tourCount = tourCount != null
                ? tourCount
                : 0L;
    }

    public List<String> getGalleryImages() {
        return galleryImages;
    }

    public void setGalleryImages(List<String> galleryImages) {
        this.galleryImages = galleryImages != null
                ? galleryImages
                : new ArrayList<>();
    }
}
