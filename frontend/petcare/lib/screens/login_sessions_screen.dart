import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginSessionsScreen extends StatefulWidget {
  const LoginSessionsScreen({Key? key}) : super(key: key);

  @override
  State<LoginSessionsScreen> createState() => _LoginSessionsScreenState();
}

class _LoginSessionsScreenState extends State<LoginSessionsScreen> {
  List<LoginSession> _sessions = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final headers = await _authService.authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/loginsession/my-sessions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> sessionsJson = data['data'];
          setState(() {
            _sessions = sessionsJson.map((json) => LoginSession.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải phiên đăng nhập: $e')),
        );
      }
    }
  }

  Future<void> _revokeSession(int sessionId, bool isCurrentSession) async {
    if (isCurrentSession) {
      // Show confirmation for current session
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc muốn đăng xuất khỏi phiên hiện tại? Bạn sẽ cần đăng nhập lại.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
    }

    try {
      final headers = await _authService.authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/loginsession/revoke/$sessionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (isCurrentSession) {
          // Logout current user
          if (mounted) {
            context.read<AuthProvider>().logout();
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        } else {
          // Reload sessions
          _loadSessions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thu hồi phiên đăng nhập')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thu hồi phiên: $e')),
        );
      }
    }
  }

  Future<void> _revokeAllSessions() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tất cả thiết bị? Bạn sẽ cần đăng nhập lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    try {
      final headers = await _authService.authHeaders();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/loginsession/revoke-all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          context.read<AuthProvider>().logout();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thu hồi tất cả phiên: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phiên đăng nhập'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _revokeAllSessions,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất tất cả thiết bị',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không có phiên đăng nhập nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
                ),
    );
  }

  Widget _buildSessionCard(LoginSession session) {
    final isCurrentSession = session.isCurrent;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(session.deviceType),
                  color: isCurrentSession ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.deviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentSession ? Colors.green : Colors.black87,
                        ),
                      ),
                      Text(
                        session.deviceType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentSession)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hiện tại',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Vị trí', session.location),
            _buildInfoRow(Icons.access_time, 'Đăng nhập lúc', _formatDateTime(session.createdAt)),
            if (session.lastUsedAt != null)
              _buildInfoRow(Icons.schedule, 'Sử dụng lần cuối', _formatDateTime(session.lastUsedAt!)),
            _buildInfoRow(Icons.event, 'Hết hạn', _formatDateTime(session.expiresAt)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _revokeSession(session.id, isCurrentSession),
                  icon: const Icon(Icons.logout, size: 16),
                  label: Text(isCurrentSession ? 'Đăng xuất' : 'Thu hồi'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'web':
        return Icons.web;
      case 'desktop':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class LoginSession {
  final int id;
  final String deviceName;
  final String deviceType;
  final String location;
  final String ipAddress;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastUsedAt;
  final bool isActive;
  final bool isCurrent;

  LoginSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.ipAddress,
    required this.createdAt,
    required this.expiresAt,
    this.lastUsedAt,
    required this.isActive,
    required this.isCurrent,
  });

  factory LoginSession.fromJson(Map<String, dynamic> json) {
    return LoginSession(
      id: json['id'],
      deviceName: json['deviceName'] ?? 'Unknown Device',
      deviceType: json['deviceType'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      ipAddress: json['ipAddress'] ?? 'Unknown IP',
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt']) : null,
      isActive: json['isActive'] ?? false,
      isCurrent: json['isCurrent'] ?? false,
    );
  }
}
