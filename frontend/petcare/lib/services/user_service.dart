import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class UserService {
  final AuthService _authService;

  UserService(this._authService);

  Future<List<User>> getAllUsers() async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final List<dynamic> userData = responseData['data'];
          return userData.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving users: $e');
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving user: $e');
    }
  }

  Future<User> getProfile() async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving profile: $e');
    }
  }

  Future<User> updateProfile(Map<String, dynamic> userData) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: headers,
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Future<List<String>> getUserRoles(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$id/roles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return List<String>.from(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load user roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving user roles: $e');
    }
  }

  Future<bool> addRoleToUser(int id, String roleName) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/$id/roles'),
        headers: headers,
        body: jsonEncode({'roleName': roleName}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to add role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding role: $e');
    }
  }

  Future<bool> removeRoleFromUser(int id, String roleName) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/$id/roles/$roleName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to remove role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing role: $e');
    }
  }
}
