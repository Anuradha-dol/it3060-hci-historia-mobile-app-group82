import '../config/api_config.dart';

class TourModel {
  final int id;
  final int userId;
  final String title;
  final String? tourDate;
  final String status;
  final int progressPercentage;
  final List<TourPlaceModel> places;

  const TourModel({
    required this.id,
    required this.userId,
    required this.title,
    this.tourDate,
    required this.status,
    required this.progressPercentage,
    required this.places,
  });

  factory TourModel.fromJson(Map<String, dynamic> json) {
    return TourModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Historical Discovery Tour',
      tourDate: json['tourDate']?.toString(),
      status: json['status']?.toString() ?? 'PLANNED',
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      places:
          (json['places'] as List?)
              ?.map(
                (item) => TourPlaceModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }
}

class TourPlaceModel {
  final int tourPlaceId;
  final int historicalPlaceId;
  final String historicalPlaceName;
  final String location;
  final String? mainImageUrl;
  final int placeOrder;
  final bool completed;
  final String? completedAt;

  const TourPlaceModel({
    required this.tourPlaceId,
    required this.historicalPlaceId,
    required this.historicalPlaceName,
    required this.location,
    this.mainImageUrl,
    required this.placeOrder,
    required this.completed,
    this.completedAt,
  });

  factory TourPlaceModel.fromJson(Map<String, dynamic> json) {
    return TourPlaceModel(
      tourPlaceId: (json['tourPlaceId'] as num?)?.toInt() ?? 0,
      historicalPlaceId: (json['historicalPlaceId'] as num).toInt(),
      historicalPlaceName: json['historicalPlaceName']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      mainImageUrl: _cleanImageUrl(json['mainImageUrl']?.toString()),
      placeOrder: (json['placeOrder'] as num?)?.toInt() ?? 0,
      completed: json['completed'] == true,
      completedAt: json['completedAt']?.toString(),
    );
  }

  static String? _cleanImageUrl(String? value) {
    final imageUrl = ApiConfig.resolveImageUrl(value);

    return imageUrl.isEmpty ? null : imageUrl;
  }
}
