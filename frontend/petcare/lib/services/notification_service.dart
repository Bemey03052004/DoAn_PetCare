import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification.dart';
import 'auth_service.dart';

class NotificationService {
  final AuthService _authService;
  NotificationService(this._authService);

  Future<List<AppNotification>> getMyNotifications() async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications');
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List list = body['data'] as List;
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> markRead(int id) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read');
    final res = await http.put(uri, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Failed to mark read');
    }
  }
}


