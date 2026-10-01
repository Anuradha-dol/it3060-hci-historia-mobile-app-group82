class GuideModel {
  final int? id;
  final int? userId;

  final String username;
  final String email;
  final String? phone;

  final String? firstName;
  final String? lastName;
  final String? address;

  final String displayName;
  final String primaryServiceArea;

  final List<String> serviceAreas;
  final List<String> languages;

  final int yearsExperience;

  final String? headline;
  final String? bio;

  final List<String> specialties;

  final String status;
  final String? adminNote;

  final String? submittedAt;
  final String? reviewedAt;
  final String? createdAt;
  final String? updatedAt;

  const GuideModel({
    this.id,
    this.userId,
    required this.username,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.address,
    required this.displayName,
    required this.primaryServiceArea,
    required this.serviceAreas,
    required this.languages,
    required this.yearsExperience,
    this.headline,
    this.bio,
    required this.specialties,
    required this.status,
    this.adminNote,
    this.submittedAt,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    return GuideModel(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      address: json['address']?.toString(),
      displayName: json['displayName']?.toString() ?? '',
      primaryServiceArea: json['primaryServiceArea']?.toString() ?? '',
      serviceAreas: List<String>.from(json['serviceAreas'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      headline: json['headline']?.toString(),
      bio: json['bio']?.toString(),
      specialties: List<String>.from(json['specialties'] ?? []),
      status: json['status']?.toString() ?? 'PENDING',
      adminNote: json['adminNote']?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  String get title {
    if (headline != null && headline!.isNotEmpty) {
      return headline!;
    }
    return displayName.isEmpty ? username : displayName;
  }
}
