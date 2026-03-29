import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
class ApiConfig {
  // Dùng 10.0.2.2 để Flutter emulator truy cập localhost
  static const String baseUrl = kIsWeb ? 'https://localhost:7267/api' : 'https://10.0.2.2:7267/api';
}
