import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_models.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _authService;

  AdminService([AuthService? authService]) : _authService = authService ?? AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<DashboardData> getDashboard() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/dashboard');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return DashboardData.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get dashboard data');
  }

  Future<List<PetDto>> getAllPets() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/pets');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => PetDto.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get pets');
  }

  Future<PetDto> updatePet(int id, UpdatePetDto dto) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/pets/$id');
    
    final body = jsonEncode(dto.toJson());
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return PetDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update pet');
  }

  Future<void> deletePet(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/pets/$id');
    
    final res = await http.delete(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode != 200 || responseBody['success'] != true) {
      throw Exception(responseBody['message'] ?? 'Failed to delete pet');
    }
  }

  Future<List<TransactionDto>> getAllTransactions() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/transactions');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => TransactionDto.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get transactions');
  }

  Future<TransactionDto> getTransactionById(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/transactions/$id');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return TransactionDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get transaction');
  }

  Future<TransactionDto> updateTransactionStatus(int id, String status) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/transactions/$id/status');
    
    final body = jsonEncode({'status': status});
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return TransactionDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update transaction status');
  }

  // User Management
  Future<List<UserDto>> getAllUsers() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => UserDto.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get users');
  }

  Future<List<String>> getUserRolesAdmin(int userId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$userId/roles');
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((e) => e.toString()).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get user roles');
  }

  Future<void> updateUserRoles(int userId, List<String> roles) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$userId/roles');
    final body = jsonEncode({'roles': roles});
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || responseBody['success'] != true) {
      throw Exception(responseBody['message'] ?? 'Failed to update user roles');
    }
  }

  Future<UserDto> getUserById(int id) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$id');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return UserDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get user');
  }

  Future<UserDto> updateUserStatus(int id, bool isActive) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$id/status');
    
    final body = jsonEncode({'isActive': isActive});
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return UserDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update user status');
  }

  Future<void> assignRole(int userId, String roleName) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$userId/roles');
    
    final body = jsonEncode({'roleName': roleName});
    final res = await http.post(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode != 200 || responseBody['success'] != true) {
      throw Exception(responseBody['message'] ?? 'Failed to assign role');
    }
  }

  Future<void> removeRole(int userId, int roleId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users-mgmt/$userId/roles/$roleId');
    
    final res = await http.delete(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode != 200 || responseBody['success'] != true) {
      throw Exception(responseBody['message'] ?? 'Failed to remove role');
    }
  }

  // Boarding Management
  Future<List<BoardingRequestDto>> getAllBoardingRequests() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/boarding-requests');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => BoardingRequestDto.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get boarding requests');
  }

  Future<BoardingRequestDto> updateBoardingRequestStatus(int id, String status) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/boarding-requests/$id/status');
    
    final body = jsonEncode({'status': status});
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return BoardingRequestDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update boarding request status');
  }

  // Adoption Management
  Future<List<AdoptionRequestDto>> getAllAdoptionRequests() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/adoption-requests');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => AdoptionRequestDto.fromJson(json)).toList();
    }
    throw Exception(responseBody['message'] ?? 'Failed to get adoption requests');
  }

  Future<AdoptionRequestDto> updateAdoptionRequestStatus(int id, String status) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/adoption-requests/$id/status');
    
    final body = jsonEncode({'status': status});
    final res = await http.put(uri, headers: headers, body: body);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return AdoptionRequestDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to update adoption request status');
  }

  // System Management
  Future<SystemStatsDto> getSystemStats() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/system-stats');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return SystemStatsDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get system stats');
  }

  Future<RecentActivitiesDto> getRecentActivities() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/recent-activities');
    
    final res = await http.get(uri, headers: headers);
    final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
    
    if (res.statusCode == 200 && responseBody['success'] == true) {
      return RecentActivitiesDto.fromJson(responseBody['data']);
    }
    throw Exception(responseBody['message'] ?? 'Failed to get recent activities');
  }
}
