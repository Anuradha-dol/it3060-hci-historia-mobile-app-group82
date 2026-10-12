/// A complete review with all details for display and editing.
class Review {
  final int id;
  final int bookingId;
  final int guideProfileId;
  final String guideName;
  final int navigationRating;
  final int informationRating;
  final int facilitiesRating;
  final String? comment;
  final int photoCount;
  final List<String> imageUrls;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.guideProfileId,
    required this.guideName,
    required this.navigationRating,
    required this.informationRating,
    required this.facilitiesRating,
    this.comment,
    required this.photoCount,
    this.imageUrls = const [],
    required this.createdAt,
  });

  /// Average rating across all three categories
  double get averageRating =>
      (navigationRating + informationRating + facilitiesRating) / 3;

  /// Factory to create from API JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      bookingId: json['bookingId'] as int,
      guideProfileId: json['guideProfileId'] as int,
      guideName: json['guideName'] as String,
      navigationRating: json['navigationRating'] as int,
      informationRating: json['informationRating'] as int,
      facilitiesRating: json['facilitiesRating'] as int,
      comment: json['comment'] as String?,
      photoCount: json['photoCount'] as int? ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON for updates
  Map<String, dynamic> toJson() {
    return {
      'navigationRating': navigationRating,
      'informationRating': informationRating,
      'facilitiesRating': facilitiesRating,
      'comment': comment,
      'photoCount': photoCount,
      'imageUrls': imageUrls,
    };
  }
}
