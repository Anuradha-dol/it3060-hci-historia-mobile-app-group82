import '../config/api_config.dart';

class HistoricalPlaceModel {
  final int id;
  final String name;
  final String location;
  final String description;
  final String? subtitle;
  final double rating;
  final int reviewCount;
  final double entranceFee;
  final String openingHours;
  final double? latitude;
  final double? longitude;
  final String? mainImageUrl;
  final List<String> galleryImages;
  final int tourCount;

  const HistoricalPlaceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.subtitle,
    required this.rating,
    required this.reviewCount,
    required this.entranceFee,
    required this.openingHours,
    this.latitude,
    this.longitude,
    this.mainImageUrl,
    this.galleryImages = const [],
    this.tourCount = 0,
  });

  factory HistoricalPlaceModel.fromJson(Map<String, dynamic> json) {
    final mainImageUrl = ApiConfig.resolveImageUrl(
      json['mainImageUrl']?.toString(),
    );

    return HistoricalPlaceModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      entranceFee: (json['entranceFee'] as num?)?.toDouble() ?? 0.0,
      openingHours: json['openingHours']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mainImageUrl: mainImageUrl.isEmpty ? null : mainImageUrl,
      galleryImages:
          (json['galleryImages'] as List?)
              ?.map((item) => ApiConfig.resolveImageUrl(item.toString()))
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const [],
      tourCount: (json['tourCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'location': location,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'entranceFee': entranceFee,
      'openingHours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
      'mainImageUrl': mainImageUrl,
      'galleryImages': galleryImages,
      'tourCount': tourCount,
    };
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
