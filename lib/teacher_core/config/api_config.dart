/// Teacher API client timeouts (base URL lives in [AppConstants.apiBaseUrl]).
class ApiConfig {
  ApiConfig._();

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
