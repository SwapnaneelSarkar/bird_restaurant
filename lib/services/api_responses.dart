// lib/services/api_response.dart

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final String? status;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.status,
  });
}
