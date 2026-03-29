import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/auth_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _service = StatsService(AuthService());
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getAdminStats();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê Admin')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _StatCard(title: 'Người dùng', value: _data!['totalUsers'].toString(), icon: Icons.people),
                      _StatCard(title: 'Thú cưng', value: _data!['totalPets'].toString(), icon: Icons.pets),
                      _StatCard(title: 'Đã nhận nuôi', value: _data!['adoptedPets'].toString(), icon: Icons.favorite),
                      _StatCard(title: 'Yêu cầu đang chờ', value: _data!['pendingAdoptions'].toString(), icon: Icons.hourglass_bottom),
                      _StatCard(title: 'Yêu cầu đã chấp nhận', value: _data!['acceptedAdoptions'].toString(), icon: Icons.check_circle),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Icon(icon, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


