class MessageResponse {
  final bool success;
  final String message;

  const MessageResponse({required this.success, required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}
