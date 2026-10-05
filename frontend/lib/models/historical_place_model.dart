class HistoricalPlaceModel {
  final int id;
  final String name;
  final String location;
  final String description;
  final double rating;
  final double entranceFee;
  final String openingHours;
  final double? latitude;
  final double? longitude;
  final String? mainImageUrl;

  const HistoricalPlaceModel({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.rating,
    required this.entranceFee,
    required this.openingHours,
    this.latitude,
    this.longitude,
    this.mainImageUrl,
  });

  factory HistoricalPlaceModel.fromJson(Map<String, dynamic> json) {
    return HistoricalPlaceModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      entranceFee:
          (json['entranceFee'] as num?)?.toDouble() ?? 0.0,
      openingHours: json['openingHours']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mainImageUrl: json['mainImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'rating': rating,
      'entranceFee': entranceFee,
      'openingHours': openingHours,
      'latitude': latitude,
      'longitude': longitude,
      'mainImageUrl': mainImageUrl,
    };
  }

  bool get hasCoordinates =>
      latitude != null && longitude != null;
}