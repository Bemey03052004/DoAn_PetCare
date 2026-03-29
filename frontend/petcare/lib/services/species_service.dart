import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/species.dart';
import 'auth_service.dart';

class SpeciesService {
  final AuthService _auth;
  SpeciesService([AuthService? auth]) : _auth = auth ?? AuthService();

  Future<List<Species>> getAll() async {
    final headers = await _auth.authHeaders();
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/species'), headers: headers);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => Species.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(body['message'] ?? 'Failed to load species');
  }

  Future<Species> create({required String name, String? description, bool isActive = true}) async {
    final headers = await _auth.authHeaders();
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/species'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'isActive': isActive,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return Species.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to create species');
  }

  Future<Species> update({required int id, required String name, String? description, required bool isActive}) async {
    final headers = await _auth.authHeaders();
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/species/$id'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'isActive': isActive,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['success'] == true) {
      return Species.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw Exception(body['message'] ?? 'Failed to update species');
  }

  Future<void> delete(int id) async {
    final headers = await _auth.authHeaders();
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/species/$id'),
      headers: headers,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete species');
    }
  }
}


