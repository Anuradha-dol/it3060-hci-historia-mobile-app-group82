class UserModel {
  final int? id;
  final String username;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String role;
  final bool emailVerified;

  const UserModel({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.address,
    required this.role,
    required this.emailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt(),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString() ?? 'TOURIST',
      emailVerified: json['emailVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
      'role': role,
      'emailVerified': emailVerified,
    };
  }

  String get fullName {
    final name = [
      firstName,
      lastName,
    ].where((value) => value != null && value.isNotEmpty).join(' ');

    return name.isEmpty ? username : name;
  }
}
