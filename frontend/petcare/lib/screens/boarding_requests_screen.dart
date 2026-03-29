import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/boarding_request.dart';
import '../providers/auth_provider.dart';
import '../services/boarding_service.dart';
import 'payment_screen.dart';

class BoardingRequestsScreen extends StatefulWidget {
  final int petId;
  final String petName;

  const BoardingRequestsScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<BoardingRequestsScreen> createState() => _BoardingRequestsScreenState();
}

class _BoardingRequestsScreenState extends State<BoardingRequestsScreen> {
  late BoardingService _boardingService;
  List<BoardingRequest> _boardingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boardingService = BoardingService(context.read<AuthProvider>().authService);
    _loadBoardingRequests();
  }

  Future<void> _loadBoardingRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final requests = await _boardingService.getReceivedBoardingRequests();
      setState(() {
        _boardingRequests = requests.where((req) => req.petId == widget.petId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBoardingStatus(int requestId, String status) async {
    try {
      await _boardingService.updateBoardingStatus(
        boardingRequestId: requestId,
        status: status,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã $status yêu cầu giữ dùm')),
      );
      
      await _loadBoardingRequests();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _confirmAndPay(BoardingRequest request) async {
    try {
      // First, update status to "Confirmed"
      await _boardingService.updateBoardingStatus(
        boardingRequestId: request.id,
        status: 'Confirmed',
      );
      
      if (!mounted) return;
      
      // Navigate to payment screen
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            type: 'boarding',
            requestId: request.id,
            amount: request.totalAmount,
            description: 'Thanh toán giữ dùm ${request.petName}',
          ),
        ),
      );
      
      if (paymentSuccess == true) {
        // Payment successful, confirm payment success
        await _boardingService.confirmPaymentSuccess(
          boardingRequestId: request.id,
          paymentReference: 'Payment completed',
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công! Bắt đầu giữ dùm.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the requests to show updated status
        await _loadBoardingRequests();
      } else {
        // Payment failed or cancelled, show message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận yêu cầu. Chờ thanh toán.'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Reload the requests to show updated status
        await _loadBoardingRequests();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác nhận và thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPayment(BoardingRequest request) async {
    try {
      // Navigate to payment screen
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            type: 'boarding',
            requestId: request.id,
            amount: request.totalAmount,
            description: 'Thanh toán giữ dùm ${request.petName}',
          ),
        ),
      );
      
      if (paymentSuccess == true) {
        // Payment successful, confirm payment success
        await _boardingService.confirmPaymentSuccess(
          boardingRequestId: request.id,
          paymentReference: 'Payment completed',
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công! Bắt đầu giữ dùm.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the requests to show updated status
        await _loadBoardingRequests();
      } else {
        // Payment failed or cancelled, show message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán bị hủy hoặc thất bại.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'inprogress':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'inprogress':
        return 'Đang giữ';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yêu cầu giữ dùm ${widget.petName}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBoardingRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi tải dữ liệu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBoardingRequests,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _boardingRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có yêu cầu giữ dùm',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Các yêu cầu giữ dùm sẽ hiển thị ở đây',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBoardingRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _boardingRequests.length,
                        itemBuilder: (context, index) {
                          final request = _boardingRequests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with customer info and status
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: Text(
                                          request.customerName.isNotEmpty 
                                              ? request.customerName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              request.customerName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Ngày gửi: ${_formatDate(request.createdAt)}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(request.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getStatusColor(request.status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(request.status),
                                          style: TextStyle(
                                            color: _getStatusColor(request.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Date range
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Thời gian giữ dùm:',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '(${_calculateDays(request.startDate, request.endDate)} ngày)',
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Price information
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.attach_money, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${request.pricePerDay.toStringAsFixed(0)} VNĐ/ngày',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Tổng: ${request.totalAmount.toStringAsFixed(0)} VNĐ',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Contact information
                                  if (request.contactPhone != null && request.contactPhone!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Liên hệ: ${request.contactPhone}',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  // Special instructions
                                  if (request.specialInstructions != null && request.specialInstructions!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Yêu cầu đặc biệt:',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            request.specialInstructions!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  // Action buttons
                                  if (request.status.toLowerCase() == 'pending') ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _updateBoardingStatus(request.id, 'Cancelled'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                            child: const Text('Từ chối'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _confirmAndPay(request),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Xác nhận'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  
                                  // Additional actions for confirmed requests (waiting for payment)
                                  if (request.status.toLowerCase() == 'confirmed') ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.payment, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Đã xác nhận - Chờ thanh toán để bắt đầu giữ dùm',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _processPayment(request),
                                        icon: const Icon(Icons.payment),
                                        label: const Text('Thanh toán'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                  
                                  // Action for in-progress requests
                                  if (request.status.toLowerCase() == 'inprogress') ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _updateBoardingStatus(request.id, 'Completed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Hoàn thành'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
}
