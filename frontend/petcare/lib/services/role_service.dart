import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/role.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class RoleService {
  final AuthService _authService;

  RoleService(this._authService);

  Future<List<Role>> getAllRoles() async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          final List<dynamic> roleData = responseData['data'];
          return roleData.map((json) => Role.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving roles: $e');
    }
  }

  Future<Role> getRoleById(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving role: $e');
    }
  }

  Future<Role> createRole(String name, String? description) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to create role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating role: $e');
    }
  }

  Future<Role> updateRole(int id, String name, String? description) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          return Role.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  Future<bool> deleteRole(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'];
      } else {
        throw Exception('Failed to delete role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting role: $e');
    }
  }

  Future<List<User>> getUsersInRole(int id) async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/roles/$id/users'),
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
        throw Exception('Failed to load users in role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error retrieving users in role: $e');
    }
  }
}
