import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class StatsService {
  final AuthService _authService;
  StatsService(this._authService);

  Future<Map<String, dynamic>> getAdminStats() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/stats/admin');
    final res = await http.get(uri, headers: headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) return body['data'] as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to load admin stats');
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/stats/user');
    final res = await http.get(uri, headers: headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) return body['data'] as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Failed to load user stats');
  }
}


