class AppNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final String recipientRole;
  final String? referenceType;
  final String? referenceId;
  final String? actionRoute;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.recipientRole,
    this.referenceType,
    this.referenceId,
    this.actionRoute,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'GENERAL',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      recipientRole: json['recipientRole']?.toString() ?? 'ACCOUNT',
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      actionRoute: json['actionRoute']?.toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      recipientRole: recipientRole,
      referenceType: referenceType,
      referenceId: referenceId,
      actionRoute: actionRoute,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
