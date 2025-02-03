class RecognitionResponse {
  final String status;
  final String? user;
  final String? error;

  RecognitionResponse({
    required this.status,
    this.user,
    this.error,
  });

  factory RecognitionResponse.fromJson(Map<String, dynamic> json) {
    return RecognitionResponse(
      status: json['status'] ?? 'Unknown',
      user: json['user'],
      error: json['error'],
    );
  }
}