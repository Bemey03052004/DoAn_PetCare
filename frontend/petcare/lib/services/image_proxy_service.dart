import 'package:http/http.dart' as http;
import 'dart:typed_data';

import 'package:petcare/config/api_config.dart';

class ImageProxyService {
  static const String _proxyUrl = '${ApiConfig.baseUrl}/imageproxy'; // Thay đổi theo server của bạn
  
  /// Lấy URL proxy cho ảnh từ server
  static String getProxyImageUrl(String originalUrl) {
    // Kiểm tra nếu là localhost hoặc URL đã có proxy
    if (originalUrl.startsWith('http://localhost') || 
        originalUrl.startsWith('http://127.0.0.1') ||
        originalUrl.startsWith('https://localhost') ||
        originalUrl.contains('imageproxy')) {
      return originalUrl; // Không cần proxy cho localhost
    }
    
    // Encode URL để truyền qua query parameter
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$_proxyUrl/proxy-safe?url=$encodedUrl';
  }
  
  /// Tải ảnh trực tiếp từ server proxy
  static Future<Uint8List?> loadImageBytes(String originalUrl) async {
    try {
      final proxyUrl = getProxyImageUrl(originalUrl);
      final response = await http.get(Uri.parse(proxyUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to load image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }
  
  /// Kiểm tra xem URL có cần proxy không
  static bool needsProxy(String url) {
    return !url.startsWith('http://localhost') && 
           !url.startsWith('http://127.0.0.1') &&
           !url.startsWith('https://localhost') &&
           !url.contains('imageproxy');
  }
  
  /// Lấy URL proxy với fallback
  static String getProxyImageUrlWithFallback(String originalUrl) {
    if (!needsProxy(originalUrl)) {
      return originalUrl;
    }
    
    // Thử proxy-safe trước (an toàn hơn)
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return '$_proxyUrl/proxy-safe?url=$encodedUrl';
  }
}
