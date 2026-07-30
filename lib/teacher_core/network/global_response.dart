class GlobalResponse<T> {
  const GlobalResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
  });

  final bool success;
  final int statusCode;
  final String message;
  final T? data;

  factory GlobalResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json)? fromJsonT,
  }) {
    final rawData = json['data'];
    return GlobalResponse<T>(
      success: json['success'] as bool? ?? false,
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: fromJsonT != null && rawData != null ? fromJsonT(rawData) : rawData as T?,
    );
  }
}
