import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  late AdminService _adminService;
  List<TransactionDto> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService(context.read<AuthProvider>().authService);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final transactions = await _adminService.getAllTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTransactionStatus(int id, String newStatus) async {
    try {
      await _adminService.updateTransactionStatus(id, newStatus);
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  Future<void> _showStatusDialog(TransactionDto transaction) async {
    final statuses = ['Pending', 'Completed', 'Failed', 'Cancelled'];
    String? selectedStatus = transaction.status;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Transaction Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Transaction: ${transaction.description}'),
              Text('Amount: ${transaction.amount.toStringAsFixed(0)} VNĐ'),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: statuses.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                )).toList(),
                onChanged: (value) => setState(() => selectedStatus = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus != null
                  ? () => Navigator.pop(context, selectedStatus)
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != transaction.status) {
      await _updateTransactionStatus(transaction.id, result);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Transactions')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTransactions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Transactions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(transaction.status),
                      child: Icon(
                        _getTypeIcon(transaction.type),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(transaction.description),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User: ${transaction.userName}'),
                        Text('Type: ${transaction.type}'),
                        Text('Date: ${transaction.createdAt.toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${transaction.amount.toStringAsFixed(0)} VNĐ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transaction.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showStatusDialog(transaction),
                  ),
                );
              },
            ),
    );
  }
}

