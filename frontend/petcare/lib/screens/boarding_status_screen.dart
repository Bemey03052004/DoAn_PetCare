import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/boarding_request.dart';
import '../providers/auth_provider.dart';

class BoardingStatusScreen extends StatefulWidget {
  final int boardingRequestId;

  const BoardingStatusScreen({super.key, required this.boardingRequestId});

  @override
  State<BoardingStatusScreen> createState() => _BoardingStatusScreenState();
}

class _BoardingStatusScreenState extends State<BoardingStatusScreen> {
  BoardingRequest? _boardingRequest;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBoardingRequest();
  }

  Future<void> _loadBoardingRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // For now, create a mock boarding request for demonstration
      // In a real implementation, you would call a service method to get the boarding request
      _boardingRequest = BoardingRequest(
        id: widget.boardingRequestId,
        petId: 1,
        petName: 'Buddy',
        petImageUrl: 'https://example.com/pet.jpg',
        ownerId: 1,
        ownerName: 'Nguyễn Văn A',
        customerId: 2,
        customerName: 'Trần Thị B',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        pricePerDay: 100000,
        totalAmount: 200000,
        specialInstructions: 'Cho ăn 2 lần/ngày',
        contactPhone: '0123456789',
        contactAddress: '123 Đường ABC, Quận 1, TP.HCM',
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải thông tin yêu cầu giữ dùm: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      case 'InProgress':
        return Colors.blue;
      case 'Completed':
        return Colors.purple;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Đang chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận - Chờ thanh toán';
      case 'Declined':
        return 'Đã từ chối';
      case 'InProgress':
        return 'Đang giữ dùm';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái giữ dùm'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBoardingRequest,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _buildBoardingStatus(),
    );
  }

  Widget _buildBoardingStatus() {
    if (_boardingRequest == null) {
      return const Center(
        child: Text('Không tìm thấy thông tin yêu cầu giữ dùm'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _getStatusColor(_boardingRequest!.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trạng thái',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_boardingRequest!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(_boardingRequest!.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(_boardingRequest!.status),
                      style: TextStyle(
                        color: _getStatusColor(_boardingRequest!.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pet Information
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin thú cưng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_boardingRequest!.petImageUrl != null && _boardingRequest!.petImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _boardingRequest!.petImageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _boardingRequest!.petName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Boarding Details
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết giữ dùm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Ngày bắt đầu', _formatDate(_boardingRequest!.startDate)),
                  _buildDetailRow('Ngày kết thúc', _formatDate(_boardingRequest!.endDate)),
                  _buildDetailRow('Giá/ngày', '${_boardingRequest!.pricePerDay.toStringAsFixed(0)} VNĐ'),
                  _buildDetailRow('Tổng tiền', '${_boardingRequest!.totalAmount.toStringAsFixed(0)} VNĐ'),
                  if (_boardingRequest!.specialInstructions != null && _boardingRequest!.specialInstructions!.isNotEmpty)
                    _buildDetailRow('Yêu cầu đặc biệt', _boardingRequest!.specialInstructions!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact Information
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Chủ thú cưng', _boardingRequest!.ownerName),
                  _buildDetailRow('Người giữ', _boardingRequest!.customerName),
                  if (_boardingRequest!.contactPhone != null && _boardingRequest!.contactPhone!.isNotEmpty)
                    _buildDetailRow('SĐT liên hệ', _boardingRequest!.contactPhone!),
                  if (_boardingRequest!.contactAddress != null && _boardingRequest!.contactAddress!.isNotEmpty)
                    _buildDetailRow('Địa chỉ liên hệ', _boardingRequest!.contactAddress!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Status Information for Customer
          _buildStatusInfo(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatusInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin trạng thái',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Status message based on current status
            _buildStatusMessage(),
            
            const SizedBox(height: 16),
            
            // Action buttons based on status
            _buildStatusActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    switch (_boardingRequest!.status) {
      case 'Pending':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu giữ dùm đang chờ chủ thú cưng xác nhận',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'Confirmed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.payment, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu đã được xác nhận. Chủ thú cưng đang thanh toán để bắt đầu giữ dùm',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'InProgress':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.pets, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đang giữ dùm thú cưng. Cả 2 người có thể chat với nhau',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'Completed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giữ dùm đã hoàn thành. Cảm ơn bạn đã giúp đỡ!',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'Declined':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu giữ dùm đã bị từ chối',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'Cancelled':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yêu cầu giữ dùm đã bị hủy',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
        
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            'Trạng thái: ${_boardingRequest!.status}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildStatusActions() {
    switch (_boardingRequest!.status) {
      case 'InProgress':
        return Column(
          children: [
            // Chat button for both users
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Use unified chat logic (same as adoption)
                  final currentUserId = context.read<AuthProvider>().user?.id;
                  final otherUserId = currentUserId == _boardingRequest!.ownerId 
                      ? _boardingRequest!.customerId 
                      : _boardingRequest!.ownerId;
                  
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: otherUserId,
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('💬 Nhắn tin với nhau'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Info about chat availability
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cả chủ thú cưng và người giữ dùm đều có thể chat với nhau',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Complete boarding button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Mark as completed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã hoàn thành giữ dùm!')),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('✅ Hoàn thành giữ dùm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
        
      case 'Completed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to chat screen for follow-up
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'roomId': 'boarding_${_boardingRequest!.id}',
                  'title': 'Chat giữ dùm ${_boardingRequest!.petName}',
                },
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('Chat với chủ thú cưng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
        
      default:
        return const SizedBox.shrink(); // No actions for other statuses
    }
  }
}
