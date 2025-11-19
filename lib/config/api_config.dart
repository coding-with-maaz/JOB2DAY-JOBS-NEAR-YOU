class ApiConfig {
  static const String baseUrl = 'https://10.0.2.2:3000/api';
  static const int timeout = 30000; // 30 seconds
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
} 