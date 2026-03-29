import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: '832295872169-idvoqq7ks67qgbga5ik6jnd10g4ve9kn.apps.googleusercontent.com',
  );

  static GoogleSignIn get googleSignIn => _googleSignIn;

  // Đăng nhập bằng Google
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Gửi thông tin Google đến backend để xác thực
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Google authentication failed: ${response.statusCode}');
      }
    } on PlatformException catch (e) {
      print('Google Sign-In Platform Error: ${e.code} - ${e.message}');
      if (e.code == 'channel-error') {
        throw Exception('Google Sign-In chưa được cấu hình đúng. Vui lòng kiểm tra file google-services.json và SHA-1 fingerprint.');
      }
      rethrow;
    } catch (error) {
      print('Google Sign-In Error: $error');
      rethrow;
    }
  }

  // Đăng xuất khỏi Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Kiểm tra trạng thái đăng nhập Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Lấy thông tin user hiện tại
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
