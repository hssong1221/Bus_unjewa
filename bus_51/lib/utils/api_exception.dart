class ApiException implements Exception {
  final String? error;
  final String? message;
  final int? statusCode;

  ApiException({this.error, this.message, this.statusCode});

  @override
  String toString() {
    return 'ApiException: $error, $message (Status code: $statusCode)';
  }
}
