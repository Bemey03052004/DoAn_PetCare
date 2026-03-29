import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'google_auth_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _tokenKey = 'auth_token';
  final _refreshTokenKey = 'refresh_token';
  final _userKey = 'user_info';

  // ====== Helpers ======
  Map<String, dynamic> _safeDecode(String body) {
    if (body.isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {'raw': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  Map<String, dynamic> _problemToResult(http.Response res, Map<String, dynamic> body) {
    // Chuẩn hoá ProblemDetails
    final Map<String, List<String>> fieldErrors = {};
    final e = body['errors'];
    if (e is Map) {
      e.forEach((k, v) {
        if (v is List) {
          fieldErrors[k.toString()] = v.map((x) => x.toString()).toList();
        } else if (v is String) {
          fieldErrors[k.toString()] = [v];
        }
      });
    }

    final messages = <String>[];
    if (body['title'] is String && (body['title'] as String).isNotEmpty) {
      messages.add(body['title']);
    }
    if (body['detail'] is String && (body['detail'] as String).isNotEmpty) {
      messages.add(body['detail']);
    }
    // gom tất cả lỗi field vào list phẳng (nếu cần)
    for (final list in fieldErrors.values) {
      messages.addAll(list);
    }
    if (messages.isEmpty && body['message'] is String) {
      messages.add(body['message']);
    }

    return {
      'success': false,
      'messages': messages,
      'fieldErrors': fieldErrors,
      'status': body['status'] ?? res.statusCode,
    };
  }

  Map<String, String> _jsonHeaders({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // ====== Public APIs ======

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode(data))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // BE có thể trả user hoặc thông báo; ta bọc vào data
        return {'success': true, 'data': body};
      }

      // Lỗi có thể ở dạng ProblemDetails
      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      
      // Get device information
      final deviceInfo = await _getDeviceInfo();
      
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({
            'email': email, 
            'password': password,
            'deviceName': deviceInfo['deviceName'],
            'deviceType': deviceInfo['deviceType'],
            'userAgent': deviceInfo['userAgent'],
          }))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode == 200) {
        // Kỳ vọng BE trả { success: true, data: { token, user } } hoặc {token,user}
        final successFlag = body['success'] == true || body.containsKey('token');
        final data = (body['data'] is Map<String, dynamic>) ? body['data'] as Map<String, dynamic> : body;

        if (successFlag && data['token'] != null) {
          await _storage.write(key: _tokenKey, value: data['token'].toString());
          if (data['refreshToken'] != null) {
            await _storage.write(key: _refreshTokenKey, value: data['refreshToken'].toString());
          }
          if (data['user'] != null) {
            await _storage.write(key: _userKey, value: jsonEncode(data['user']));
          }
          return {'success': true, 'data': data};
        }
        // 200 nhưng không có token → coi như lỗi định dạng
        return {
          'success': false,
          'messages': ['Invalid login response: token missing'],
          'status': res.statusCode,
        };
      }

      // Lỗi có thể ở dạng ProblemDetails
      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<User?> getStoredUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return User.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await getValidToken();
    return _jsonHeaders(token: token);
  }

  // Get valid token with auto refresh
  Future<String?> getValidToken() async {
    final token = await getToken();
    if (token == null) return null;

    // Check if token is expired or about to expire
    if (_isTokenExpired(token)) {
      // Try to refresh token
      final refreshResult = await refreshToken();
      if (refreshResult['success'] == true) {
        return refreshResult['data']['token'];
      } else {
        // Refresh failed, logout user
        await logout();
        return null;
      }
    }

    return token;
  }

  // Check if token is expired or about to expire (within 5 minutes)
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      // Consider token expired if it expires within 5 minutes
      return expirationDate.isBefore(now.add(const Duration(minutes: 5)));
    } catch (e) {
      return true; // If we can't parse the token, consider it expired
    }
  }

  // Refresh token method
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        return {'success': false, 'messages': ['No refresh token available']};
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({'refreshToken': refreshTokenValue}))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode == 200) {
        final successFlag = body['success'] == true || body.containsKey('token');
        final data = (body['data'] is Map<String, dynamic>) ? body['data'] as Map<String, dynamic> : body;

        if (successFlag && data['token'] != null) {
          // Update stored tokens
          await _storage.write(key: _tokenKey, value: data['token'].toString());
          if (data['refreshToken'] != null) {
            await _storage.write(key: _refreshTokenKey, value: data['refreshToken'].toString());
          }
          if (data['user'] != null) {
            await _storage.write(key: _userKey, value: jsonEncode(data['user']));
          }
          return {'success': true, 'data': data};
        }
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  // ====== Forgot Password & Email Verification ======

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({'email': email}))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-code');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({
            'email': email,
            'code': code,
          }))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/reset-password');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({
            'email': email,
            'code': code,
            'newPassword': newPassword,
          }))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/verify-email');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({
            'email': email,
            'code': code,
          }))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/resend-verification');
      final res = await http
          .post(uri, headers: _jsonHeaders(), body: jsonEncode({'email': email}))
          .timeout(const Duration(seconds: 20));

      final body = _safeDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {'success': true, 'data': body};
      }

      return _problemToResult(res, body);
    } on TimeoutException {
      return {'success': false, 'messages': ['Request timed out. Please try again.']};
    } catch (e) {
      return {'success': false, 'messages': ['Network error: $e']};
    }
  }

  // ====== Google Authentication ======

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleResult = await GoogleAuthService.signInWithGoogle();
      
      if (googleResult == null) {
        return {'success': false, 'messages': ['Google sign-in cancelled']};
      }

      if (googleResult['success'] == true) {
        // Lưu token và user info
        await _storage.write(key: _tokenKey, value: googleResult['data']['token']);
        if (googleResult['data']['refreshToken'] != null) {
          await _storage.write(key: _refreshTokenKey, value: googleResult['data']['refreshToken']);
        }
        await _storage.write(key: _userKey, value: jsonEncode(googleResult['data']['user']));
        
        return {
          'success': true,
          'data': {
            'user': googleResult['data']['user'],
            'token': googleResult['data']['token'],
            'refreshToken': googleResult['data']['refreshToken'],
          }
        };
      } else {
        return {
          'success': false,
          'messages': googleResult['messages'] ?? ['Google authentication failed']
        };
      }
    } catch (e) {
      return {'success': false, 'messages': ['Google authentication error: $e']};
    }
  }

  Future<void> signOutGoogle() async {
    await GoogleAuthService.signOut();
    await logout();
  }

  // Get device information for login session tracking
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      // For mobile apps, you would use device_info_plus package
      // For now, we'll use basic info
      return {
        'deviceName': 'Flutter App', // Could be device model
        'deviceType': 'Mobile', // Mobile, Web, Desktop
        'userAgent': 'PetCare Flutter App v1.0', // App version info
      };
    } catch (e) {
      return {
        'deviceName': 'Unknown Device',
        'deviceType': 'Mobile',
        'userAgent': 'PetCare Flutter App',
      };
    }
  }
}
