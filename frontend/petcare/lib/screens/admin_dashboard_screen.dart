import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _adminService.getDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _dashboardData == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildRecentPets(),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Pets',
          _dashboardData!.totalPets.toString(),
          Icons.pets,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Users',
          _dashboardData!.totalUsers.toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Total Revenue',
          '${_dashboardData!.totalRevenue.toStringAsFixed(0)} VNĐ',
          Icons.attach_money,
          Colors.orange,
        ),
        _buildStatCard(
          'Success Rate',
          '${_dashboardData!.successRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPets() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Pets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/pets');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dashboardData!.recentPets.isEmpty)
              const Text('No recent pets')
            else
              ..._dashboardData!.recentPets.map((pet) => ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (pet.imageUrl?.isNotEmpty ?? false)
                          ? NetworkImage(pet.imageUrl!)
                          : null,
                      child: (pet.imageUrl?.isEmpty ?? true)
                          ? const Icon(Icons.pets)
                          : null,
                    ),
                    title: Text(pet.name),
                    subtitle: Text('${pet.species} - ${pet.breed}'),
                    trailing: Text(
                      pet.isPublic ? 'Public' : 'Private',
                      style: TextStyle(
                        color: pet.isPublic ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/transactions');
                  },
                  child: const Text('View All'),
                )],
            ),
            const SizedBox(height: 16),
            if (_dashboardData!.recentTransactions.isEmpty)
              const Text('No recent transactions')
            else
              ..._dashboardData!.recentTransactions.map((transaction) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTransactionColor(transaction.status),
                      child: Icon(
                        _getTransactionIcon(transaction.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(transaction.description),
                    subtitle: Text('${transaction.userName} - ${transaction.type}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${transaction.amount.toStringAsFixed(0)} VNĐ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          transaction.status,
                          style: TextStyle(
                            color: _getTransactionColor(transaction.status),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Color _getTransactionColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'boarding':
        return Icons.home;
      case 'sale':
        return Icons.sell;
      case 'adoption':
        return Icons.favorite;
      default:
        return Icons.payment;
    }
  }
}
