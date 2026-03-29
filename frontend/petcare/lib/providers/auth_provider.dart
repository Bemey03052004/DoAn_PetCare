import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../exceptions/email_not_verified_exception.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  AuthService get authService => _authService;

  AuthProvider() {
    _loadUser();
  }
  Future<bool> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token != null) {
      _user = await _authService.getStoredUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _loadUser() async {
    final token = await _authService.getToken();
    if (token != null) {
      final userData = await _storage.read(key: 'user_info');
      if (userData != null) {
        _user = User.fromJson(jsonDecode(userData));
        _isAuthenticated = true;
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _authService.register(data);
    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _authService.login(email, password);
    if (response['success']) {
      _isAuthenticated = true;
      _user = User.fromJson(response['data']['user']);
      notifyListeners();
    } else {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      final errorMessage = messages.join(', ');
      
      // Kiểm tra nếu lỗi là email chưa được xác thực
      if (errorMessage.contains('Email not verified') || errorMessage.contains('verify your email')) {
        throw EmailNotVerifiedException(errorMessage);
      }
    }
    return response;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  void updateCurrentUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  // ====== Forgot Password & Email Verification ======

  Future<void> forgotPassword(String email) async {
    final response = await _authService.forgotPassword(email);
    if (!response['success']) {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      throw Exception(messages.join(', '));
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    final response = await _authService.verifyResetCode(email, code);
    if (!response['success']) {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      throw Exception(messages.join(', '));
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    final response = await _authService.resetPassword(email, code, newPassword);
    if (!response['success']) {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      throw Exception(messages.join(', '));
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    final response = await _authService.verifyEmail(email, code);
    if (!response['success']) {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      throw Exception(messages.join(', '));
    }
  }

  Future<void> resendVerificationCode(String email) async {
    final response = await _authService.resendVerificationCode(email);
    if (!response['success']) {
      final messages = response['messages'] as List<String>? ?? ['Có lỗi xảy ra'];
      throw Exception(messages.join(', '));
    }
  }

  // ====== Google Authentication ======

  Future<Map<String, dynamic>> loginWithGoogle() async {
    final response = await _authService.loginWithGoogle();
    if (response['success']) {
      _isAuthenticated = true;
      _user = User.fromJson(response['data']['user']);
      notifyListeners();
    }
    return response;
  }

  Future<void> signOutGoogle() async {
    await _authService.signOutGoogle();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
