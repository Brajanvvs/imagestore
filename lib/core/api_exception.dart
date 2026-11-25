class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fields = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> fields;

  @override
  String toString() => message;
}
