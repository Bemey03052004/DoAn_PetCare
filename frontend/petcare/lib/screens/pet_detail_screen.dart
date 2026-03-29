import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../models/pet.dart';
import '../models/boarding_request.dart';
import '../models/price_offer.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../services/sale_service.dart';
import '../services/boarding_service.dart';
import '../services/auth_service.dart';
import '../services/price_offer_service.dart';
import '../services/image_proxy_service.dart';
import 'pet_adoption_requests_screen.dart';
import 'payment_screen.dart';
import 'sale_requests_screen.dart';
import 'boarding_requests_screen.dart';
import 'boarding_status_screen.dart';
import 'edit_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> with TickerProviderStateMixin {
  Pet? _pet;
  bool _loading = true;
  String? _error;
  late TabController _tabController;
  late SaleService _saleService;
  late BoardingService _boardingService;
  late PriceOfferService _priceOfferService;

  // Removed GoogleMapController; switch to flutter_map (OpenStreetMap)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _saleService = SaleService(context.read<AuthProvider>().authService);
    _boardingService = BoardingService(context.read<AuthProvider>().authService);
    _priceOfferService = PriceOfferService(context.read<AuthProvider>().authService);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final petDetail = await context.read<PetProvider>().loadPetDetail(widget.petId);
    setState(() {
      _pet = petDetail;
      _loading = false;
      if (petDetail == null) _error = 'Không tải được chi tiết thú cưng';
    });
  }

  Future<List<BoardingRequest>> _getBoardingRequestsForPet(int petId) async {
    try {
      final boardingService = BoardingService(AuthService());
      final requests = await boardingService.getReceivedBoardingRequests();
      return requests.where((req) => req.petId == petId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BoardingRequest>> _getMyBoardingRequestsForPet(int petId) async {
    try {
      final boardingService = BoardingService(AuthService());
      final requests = await boardingService.getMyBoardingRequests();
      return requests.where((req) => req.petId == petId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> _getMySaleRequestStatusForPet(int petId) async {
    try {
      final saleService = SaleService(AuthService());
      final requests = await saleService.getMySaleRequests();
      final myRequest = requests.where((req) => req.petId == petId).firstOrNull;
      return myRequest?.status;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getSaleRequestDetailsForPet(int petId) async {
    try {
      final saleService = SaleService(AuthService());
      final request = await saleService.getSaleRequestForPet(petId);
      
      if (request != null) {
        return {
          'amount': request.amount,
          'message': request.message ?? '',
          'status': request.status,
        };
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<PriceOffer?> _getMyPriceOfferForPet(int petId) async {
    try {
      return await _priceOfferService.getMyOfferForPet(petId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildSaleRequestStatusWithPrice(String status, Pet pet) {
    debugPrint('Status: $status');
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSaleRequestDetailsForPet(pet.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final requestDetails = snapshot.data;
        final amount = requestDetails?['amount'] as double? ?? 0.0;
        final message = requestDetails?['message'] as String? ?? '';
        return _buildSaleRequestStatusWithDetails(status, pet, amount, message);
      },
    );
  }

  Widget _buildSaleRequestStatusWithDetails(String status, Pet pet, double amount, String message) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã gửi yêu cầu mua',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yêu cầu của bạn đang chờ chủ thú cưng xác nhận.',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giá đề xuất:',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${amount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ghi chú: $message',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      
      case 'confirmed':
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sẵn sàng thanh toán',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yêu cầu mua đã được xác nhận. Bạn có thể thanh toán ngay.',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToPayment(pet),
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        );
      
      case 'rejected':
      case 'declined':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu cầu bị từ chối',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chủ thú cưng đã từ chối yêu cầu mua của bạn.',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giá đề xuất:',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${amount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ghi chú: $message',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      
      case 'completed':
        return const SizedBox.shrink();
      
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trạng thái: $status',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPriceOfferStatus(PriceOffer offer, Pet pet) {
    switch (offer.status.toLowerCase()) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đề xuất giá đang chờ',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giá đề xuất: ${offer.offeredAmount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (offer.message != null && offer.message!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú: ${offer.message}',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      
      case 'accepted':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đề xuất giá đã được chấp nhận',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giá đã chấp nhận: ${offer.offeredAmount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (offer.message != null && offer.message!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú: ${offer.message}',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToPayment(pet, acceptedOffer: offer),
                icon: const Icon(Icons.payment),
                label: const Text('Thanh toán ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      
      case 'rejected':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đề xuất giá bị từ chối',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giá bị từ chối: ${offer.offeredAmount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (offer.message != null && offer.message!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú: ${offer.message}',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      
      case 'counteroffered':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Có đề xuất giá ngược lại',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giá đề xuất của bạn: ${offer.offeredAmount.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (offer.counterOfferAmount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Giá đề xuất ngược lại: ${offer.counterOfferAmount!.toStringAsFixed(0)} VNĐ',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (offer.counterOfferMessage != null && offer.counterOfferMessage!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ghi chú từ chủ: ${offer.counterOfferMessage}',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPriceOfferDialog(pet, context.read<AuthProvider>().user),
                      icon: const Icon(Icons.edit),
                      label: const Text('Đề xuất lại'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBuyDialog(pet, context.read<AuthProvider>().user),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Mua ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trạng thái đề xuất: ${offer.status}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }


  Future<void> _navigateToPayment(Pet pet, {PriceOffer? acceptedOffer}) async {
    try {
      // Get the sale request for this pet
      final saleService = SaleService(AuthService());
      final requests = await saleService.getMySaleRequests();
      final myRequest = requests.where((req) => req.petId == pet.id).firstOrNull;
      
      if (myRequest == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy yêu cầu mua bán')),
        );
        return;
      }
      
      // Use accepted offer amount if available, otherwise use sale request amount
      final paymentAmount = acceptedOffer?.offeredAmount ?? myRequest.amount;
      
      // Navigate to payment screen
      final paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            type: 'sale',
            requestId: myRequest.id,
            amount: paymentAmount,
            description: 'Mua thú cưng ${pet.name}',
          ),
        ),
      );
      
      if (paymentSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán thành công!')),
        );
        // Refresh the screen to update status
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán không thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _showPetAgain(Pet pet) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hiện lại thú cưng'),
          content: const Text('Bạn có chắc chắn muốn hiện lại thú cưng này để bán/nhận nuôi lại không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Call API to show pet again
      final updated = await context.read<PetProvider>().showPetAgain(pet.id!);
      if (!mounted) return;
      
      if (updated != null) {
        setState(() => _pet = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hiện lại thú cưng thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể hiện lại thú cưng')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _showAdoptionDialog(Pet pet, dynamic currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhận nuôi thú cưng'),
        content: Text('Bạn có chắc chắn muốn nhận nuôi ${pet.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement adoption request creation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yêu cầu nhận nuôi đã được gửi')),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getSaleHistoryForPet(int petId) async {
    try {
      final saleService = SaleService(AuthService());
      final requests = await saleService.getMySaleRequests();
      final myRequest = requests.where((req) => req.petId == petId).firstOrNull;
      
      if (myRequest != null) {
        return {
          'isCompleted': myRequest.status == 'Completed',
          'wasMyPurchase': true,
          'saleRequest': myRequest,
        };
      }
      
      return {
        'isCompleted': false,
        'wasMyPurchase': false,
        'saleRequest': null,
      };
    } catch (e) {
      return {
        'isCompleted': false,
        'wasMyPurchase': false,
        'saleRequest': null,
      };
    }
  }

  Widget _buildPurchaseHistory(Map<String, dynamic> saleHistory) {
    final saleRequest = saleHistory['saleRequest'];
    if (saleRequest == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Lịch sử mua hàng',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RowInfo('Trạng thái', 'Đã mua thành công'),
          _RowInfo('Giá mua', '${saleRequest.amount.toStringAsFixed(0)} VNĐ'),
          if (saleRequest.message != null && saleRequest.message!.isNotEmpty)
            _RowInfo('Ghi chú', saleRequest.message!),
          _RowInfo('Ngày mua', _formatDate(saleRequest.createdAt)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn có thể mua lại thú cưng này nếu muốn.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPetStatusText(Pet pet) {
    if (pet.isAdopted) {
      return 'Đã được nhận nuôi';
    } else if (pet.isForSale) {
      return 'Đang bán';
    } else if (pet.isForBoarding) {
      return 'Đang cho thuê giữ dùm';
    } else if (pet.isHidden) {
      return 'Đã ẩn';
    } else if (pet.isPublic) {
      return 'Đang tìm chủ mới';
    } else {
      return 'Không xác định';
    }
  }

  String _getAdoptionRequestStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Đang chờ duyệt';
      case 'accepted':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Đã từ chối';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getAdoptionRequestColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getPetStatusColor(Pet pet) {
    if (pet.isAdopted) {
      return Colors.green;
    } else if (pet.isForSale) {
      return Colors.blue;
    } else if (pet.isForBoarding) {
      return Colors.orange;
    } else if (pet.isHidden) {
      return Colors.grey;
    } else if (pet.isPublic) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    final pet = _pet!;
    final isOwner = currentUser != null && currentUser.id == pet.ownerId;
    final canPublish = isOwner || (currentUser?.isAdmin == true);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thú cưng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Mua bán'),
            Tab(text: 'Giữ dùm'),
            Tab(text: 'Tặng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(pet, isOwner, canPublish),
          _buildSaleTab(pet, isOwner, currentUser),
          _buildBoardingTab(pet, isOwner, currentUser),
          _buildAdoptionTab(pet, isOwner, currentUser),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Pet pet, bool isOwner, bool canPublish) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header ảnh + overlay + tiêu đề
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: pet.imageUrl != null
                      ? Image.network(
                          ImageProxyService.getProxyImageUrl(pet.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.pets, size: 72),
                              ),
                            );
                          },
                        )
                      : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.pets, size: 72))),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(icon: Icons.pets, label: pet.species),
                        _Chip(icon: Icons.cake_outlined, label: '${pet.ageMonths} tháng'),
                        if (pet.breed != null && pet.breed!.isNotEmpty) _Chip(icon: Icons.badge_outlined, label: pet.breed!),
                        if (pet.gender != null && pet.gender!.isNotEmpty) _Chip(icon: Icons.male, label: pet.gender!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thông tin tổng quan
          _SectionCard(
            title: 'Tổng quan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewItem(
                        icon: Icons.pets,
                        label: 'Loài',
                        value: pet.species,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOverviewItem(
                        icon: Icons.male,
                        label: 'Giới tính',
                        value: pet.gender ?? 'Không xác định',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewItem(
                        icon: Icons.cake,
                        label: 'Tuổi',
                        value: '${pet.ageMonths} tháng',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOverviewItem(
                        icon: Icons.info_outline,
                        label: 'Trạng thái',
                        value: _getPetStatusText(pet),
                        color: _getPetStatusColor(pet),
                      ),
                    ),
                  ],
                ),
                if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildOverviewItem(
                    icon: Icons.category,
                    label: 'Giống',
                    value: pet.breed!,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          ),

          // Thông tin cơ bản
          _SectionCard(
            title: 'Thông tin cơ bản',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowInfo('ID thú cưng', pet.id?.toString() ?? 'N/A'),
                _RowInfo('Tên', pet.name),
                _RowInfo('Loài', pet.species),
                if (pet.breed != null && pet.breed!.isNotEmpty)
                  _RowInfo('Giống', pet.breed!),
                _RowInfo('Giới tính', pet.gender ?? 'Không xác định'),
                _RowInfo('Tuổi', '${pet.ageMonths} tháng'),
                _RowInfo('Trạng thái', _getPetStatusText(pet)),
                _RowInfo('Công khai', pet.isPublic ? 'Có' : 'Không'),
                _RowInfo('Đã ẩn', pet.isHidden ? 'Có' : 'Không'),
                _RowInfo('Đã được nhận nuôi', pet.isAdopted ? 'Có' : 'Không'),
                _RowInfo('Đang bán', pet.isForSale ? 'Có' : 'Không'),
                _RowInfo('Đang cho thuê giữ dùm', pet.isForBoarding ? 'Có' : 'Không'),
                _RowInfo('Mô tả', pet.description ?? 'Không có'),
                if (pet.createdAt != null)
                  _RowInfo('Ngày tạo', _formatDate(pet.createdAt!)),
              ],
            ),
          ),

          // Thông tin chủ sở hữu
          if (pet.owner != null)
            _SectionCard(
              title: 'Thông tin chủ sở hữu',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('ID chủ', pet.owner!.id.toString()),
                  _RowInfo('Tên chủ', pet.owner!.fullName),
                  _RowInfo('Email', pet.owner!.email),
                  if (pet.owner!.phone != null && pet.owner!.phone!.isNotEmpty)
                    _RowInfo('Số điện thoại', pet.owner!.phone!),
                  if (pet.owner!.address != null && pet.owner!.address!.isNotEmpty)
                    _RowInfo('Địa chỉ', pet.owner!.address!),
                  _RowInfo('Ngày tham gia', _formatDate(pet.owner!.createdAt)),
                ],
              ),
            ),

          // Thông tin tiêm chủng
          if (pet.vaccinationSchedules != null && pet.vaccinationSchedules!.isNotEmpty)
            _SectionCard(
              title: 'Lịch tiêm chủng',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('Tổng số lịch tiêm', pet.vaccinationSchedules!.length.toString()),
                  const SizedBox(height: 8),
                  ...pet.vaccinationSchedules!.map((vaccination) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: vaccination.isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: vaccination.isCompleted ? Colors.green.shade200 : Colors.blue.shade200
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                vaccination.isCompleted ? Icons.check_circle : Icons.schedule,
                                color: vaccination.isCompleted ? Colors.green : Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vaccination.isCompleted ? 'Đã hoàn thành' : 'Chưa hoàn thành',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: vaccination.isCompleted ? Colors.green : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _RowInfo('Tên vắc-xin', vaccination.vaccineName),
                          _RowInfo('Ngày dự kiến', _formatDate(vaccination.scheduledDate)),
                          if (vaccination.completedAt != null)
                            _RowInfo('Ngày hoàn thành', _formatDate(vaccination.completedAt!)),
                          _RowInfo('Ngày tạo lịch', _formatDate(vaccination.createdAt)),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),

          // Thông tin boarding hiện tại
          if (pet.isCurrentlyBoarded != null && pet.isCurrentlyBoarded!)
            _SectionCard(
              title: 'Trạng thái giữ dùm hiện tại',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('Trạng thái', 'Đang được giữ dùm'),
                  if (pet.currentBoardingCustomerId != null)
                    _RowInfo('ID khách hàng', pet.currentBoardingCustomerId.toString()),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thú cưng hiện đang được giữ dùm bởi khách hàng khác',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Thông tin boarding (nếu có)
          if (pet.isForBoarding != null && pet.isForBoarding!)
            _SectionCard(
              title: 'Thông tin dịch vụ giữ dùm',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('Giá mỗi ngày', '${pet.boardingPricePerDay?.toStringAsFixed(0) ?? 'N/A'} VNĐ'),
                  if (pet.boardingStartDate != null)
                    _RowInfo('Ngày bắt đầu', _formatDate(pet.boardingStartDate!)),
                  if (pet.boardingEndDate != null)
                    _RowInfo('Ngày kết thúc', _formatDate(pet.boardingEndDate!)),
                  if (pet.boardingDescription != null && pet.boardingDescription!.isNotEmpty)
                    _RowInfo('Mô tả dịch vụ', pet.boardingDescription!),
                ],
              ),
            ),

          // Thông tin yêu cầu nhận nuôi
          if (pet.adoptionRequests != null && pet.adoptionRequests!.isNotEmpty)
            _SectionCard(
              title: 'Yêu cầu nhận nuôi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('Số lượng yêu cầu', pet.adoptionRequests!.length.toString()),
                  const SizedBox(height: 8),
                  ...pet.adoptionRequests!.map((request) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getAdoptionRequestColor(request.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getAdoptionRequestColor(request.status).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RowInfo('ID người yêu cầu', request.userId.toString()),
                          _RowInfo('Trạng thái', _getAdoptionRequestStatusText(request.status)),
                          if (request.message != null && request.message!.isNotEmpty)
                            _RowInfo('Tin nhắn', request.message!),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),


          // Hồ sơ xã hội
          if (pet.profile != null)
            _SectionCard(
              title: 'Hồ sơ xã hội',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowInfo('ID hồ sơ', pet.profile!.id.toString()),
                  if (pet.profile!.personality != null && pet.profile!.personality!.isNotEmpty)
                    _RowInfo('Tính cách', pet.profile!.personality!),
                  if (pet.profile!.favoriteFood != null && pet.profile!.favoriteFood!.isNotEmpty)
                    _RowInfo('Món yêu thích', pet.profile!.favoriteFood!),
                  if (pet.profile!.hobbies != null && pet.profile!.hobbies!.isNotEmpty)
                    _RowInfo('Sở thích', pet.profile!.hobbies!),
                  if (pet.profile!.story != null && pet.profile!.story!.isNotEmpty)
                    _RowInfo('Câu chuyện', pet.profile!.story!),
                  if (pet.profile!.socialImage != null && pet.profile!.socialImage!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ảnh xã hội',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ImageProxyService.getProxyImageUrl(pet.profile!.socialImage!),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: Icon(
                                  Icons.pets,
                                  color: Colors.grey.shade400,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Bản đồ vị trí
          _SectionCard(
            title: 'Vị trí chủ nuôi',
            child: _OwnerMapSection(
              ownerLat: pet.owner?.latitude, 
              ownerLng: pet.owner?.longitude,
              ownerName: pet.owner?.fullName,
              petGender: pet.gender,
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(pet, isOwner, canPublish),
          ),

          const SizedBox(height: 90), // chừa khoảng dưới
        ],
      ),
    );
  }

  Widget _buildSaleTab(Pet pet, bool isOwner, dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale info
          if (pet.isForSale) ...[
            _SectionCard(
              title: 'Thông tin bán',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOwner) ...[
                    // Inline edit for owner
                    _buildInlinePriceEdit(pet),
                    const SizedBox(height: 16),
                    _buildInlineDescriptionEdit(pet),
                  ] else ...[
                    // Display only for non-owners
                    if (pet.price != null)
                      _RowInfo('Giá bán', '${pet.price!.toStringAsFixed(0)} VNĐ'),
                    if (pet.saleDescription != null && pet.saleDescription!.isNotEmpty)
                      _RowInfo('Mô tả bán', pet.saleDescription!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sale actions
          if (!isOwner && pet.isForSale) ...[
            // Check if pet is adopted and if current user was the buyer
            FutureBuilder<Map<String, dynamic>>(
              future: _getSaleHistoryForPet(pet.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final saleHistory = snapshot.data;
                final wasMyPurchase = saleHistory?['wasMyPurchase'] as bool? ?? false;
                debugPrint('saleHistory: $saleHistory');
                debugPrint('wasMyPurchase: $wasMyPurchase');
                debugPrint('IsAdopted: ${pet.isAdopted}');
                if (!pet.isAdopted && wasMyPurchase) {
                  // Show purchase history and check for price offers
                  return FutureBuilder<PriceOffer?>(
                    future: _getMyPriceOfferForPet(pet.id!),
                    builder: (context, offerSnapshot) {
                      if (offerSnapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            _buildPurchaseHistory(saleHistory!),
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        );
                      }
                      
                      final priceOffer = offerSnapshot.data;
                      
                      if (priceOffer != null) {
                        // User has a price offer - show offer status instead of buy button
                        return Column(
                          children: [
                            _buildPurchaseHistory(saleHistory!),
                            const SizedBox(height: 16),
                            _buildPriceOfferStatus(priceOffer, pet),
                          ],
                        );
                      } else {
                        // No price offer - show buy button and price offer button
                        return Column(
                          children: [
                            _buildPurchaseHistory(saleHistory!),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showBuyDialog(pet, currentUser),
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('Mua lại thú cưng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showPriceOfferDialog(pet, currentUser),
                              icon: const Icon(Icons.attach_money),
                              label: const Text('Đề xuất giá'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  );
                } else if (pet.isAdopted && !wasMyPurchase) {
                  // Pet is adopted but not by current user
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thú cưng này đã được bán cho người khác',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!pet.isAdopted) {
                  // Check sale request status for current user

                  return FutureBuilder<String?>(
                    future: _getMySaleRequestStatusForPet(pet.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final status = snapshot.data;
                      
                      if (status == null) {
                        // No request - check for price offers first
                        return FutureBuilder<PriceOffer?>(
                          future: _getMyPriceOfferForPet(pet.id!),
                          builder: (context, offerSnapshot) {
                            if (offerSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final priceOffer = offerSnapshot.data;
                            
                            if (priceOffer != null) {
                              // Show price offer status
                              return _buildPriceOfferStatus(priceOffer, pet);
                            } else {
                              // No offer - show buy and offer buttons
                              return Column(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showBuyDialog(pet, currentUser),
                                    icon: const Icon(Icons.shopping_cart),
                                    label: const Text('Mua thú cưng'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _showPriceOfferDialog(pet, currentUser),
                                    icon: const Icon(Icons.attach_money),
                                    label: const Text('Đề xuất giá'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        );
                      }

                      // Show status based on request status with price info
                      return _buildSaleRequestStatusWithPrice(status, pet);
                    },
                  );
                } else {
                  // Default case - should not happen
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Không thể xác định trạng thái',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ] else if (isOwner) ...[
            // Owner management for sale
            if (pet.isForSale) ...[
              ElevatedButton.icon(
                onPressed: () => _navigateToSaleRequests(context, pet),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Quản lý yêu cầu mua bán'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.deepPurpleAccent.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Quản lý dịch vụ mua bán',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurpleAccent.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn có thể quản lý các yêu cầu mua bán thú cưng của mình tại đây. Khi có người yêu cầu trả giá bạn sẽ cần xác nhận.',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          ] else if (pet.isAdopted) ...[
            Center(
              child: Text(
                'Thú cưng đã được nhận nuôi',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),  
          ] else ...[
            Center(
              child: Text(
                'Thú cưng không được bán',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdoptionTab(Pet pet, bool isOwner, dynamic currentUser) {
    if (pet.adoptionRequests != null) {
      for (var req in pet.adoptionRequests!) {
        debugPrint('  - Request ${req.id}: userId=${req.userId}, status=${req.status}');
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adoption info
            _SectionCard(
              title: 'Thông tin tặng',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (pet.adoptionRequests?.isEmpty==true) ...[
                      _RowInfo('Trạng thái', 'Đang tìm chủ mới'),
                      _RowInfo('Message', 'Không có'),
                    ] else if (pet.adoptionRequests?.any((r) => r.userId == currentUser.id) == true) ...[
                      _RowInfo('Trạng thái', 'Đã được bạn nhận nuôi'),
                      _RowInfo(
                        'Message',
                        pet.adoptionRequests!
                            .firstWhereOrNull((r) => r.userId == currentUser.id)
                            ?.message ?? 'Không có',
                      ),
                      _RowInfo(
                        'Chủ đã accept ?',
                            () {
                          final reqStatus = pet.adoptionRequests!
                              .firstWhereOrNull((r) => r.userId == currentUser.id)
                              ?.status;
                          if (reqStatus == null) return 'Không có';
                          return (reqStatus == 'Accepted') ? 'Rồi' : 'Chưa';
                        }(),
                      ),
                    ] else ...[
                      _RowInfo('Trạng thái', 'Đang được nhận nuôi hoặc bán'),
                      _RowInfo('Chủ hiện tại có id là', (pet.adoptionRequests?.isNotEmpty == true)
                      ? pet.adoptionRequests!.first.userId.toString()
                          : 'Không có'),

                    ],

                    if (pet.description?.isNotEmpty == true)
                      _RowInfo('Mô tả', pet.description!),
                  ]

              ),
            ),
            const SizedBox(height: 16),

          // Adoption actions - complete logic moved from Info tab
          if (!isOwner && !pet.isAdopted ) ...[
            // Complete adoption logic from Info tab - works for all cases
            FutureBuilder<String?>(
              future: Future.value(context.read<PetProvider>().getMyAdoptionStatusForPet(pet.id!)),
              builder: (context, snapshot) {
                final status = snapshot.data;
                if (status == 'Accepted') {
                  return ElevatedButton.icon(
                    onPressed: () {
                      final ownerId = pet.ownerId;
                      Navigator.pushNamed(
                        context, 
                        '/chat', 
                        arguments: {
                          'otherUserId': ownerId,
                          'petName': pet.name,
                          'chatType': 'adoption',
                        },
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Nhắn tin với chủ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                }
                if (status == 'Pending') {
                  return ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.hourglass_top),
                    label: const Text('Đang chờ duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                }
                if (status == 'Declined') {
                  return ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.block),
                    label: const Text('Đã bị từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                }
                // Show adoption button only if pet is not for sale or boarding
                if (!pet.isForSale && !pet.isForBoarding) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      final textCtrl = TextEditingController();
                      final msg = await showDialog<String?>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Lời nhắn nhận nuôi (tuỳ chọn)'),
                          content: TextField(
                            controller: textCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(hintText: 'Tin nhắn gửi chủ...'),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Bỏ qua')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, textCtrl.text.trim()), child: const Text('Gửi')),
                          ],
                        ),
                      );
                      if (msg == null && !mounted) return;
                      try {
                        final ok = await context.read<PetProvider>().createAdoptionRequest(pet.id!, message: msg);
                        if (!mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu nhận nuôi.')));
                          setState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu thất bại.')));
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text('Gửi yêu cầu nhận nuôi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                } else {
                  // Pet is for sale or boarding - show info message
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pet.isForSale && pet.isForBoarding 
                              ? 'Thú cưng này đang được bán và giữ dùm. Không thể nhận nuôi miễn phí.'
                              : pet.isForSale 
                                ? 'Thú cưng này đang được bán. Không thể nhận nuôi miễn phí.'
                                : 'Thú cưng này đang có dịch vụ giữ dùm. Không thể nhận nuôi miễn phí.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ] else if (isOwner) ...[
            // Owner management for adoption
            if (!pet.isForSale && !pet.isForBoarding) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PetAdoptionRequestsScreen(petId: pet.id!)),
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text('Quản lý yêu cầu nhận nuôi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (pet.isForSale || pet.isForBoarding) ...[
              // Show message when pet is for sale or boarding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pet.isForSale && pet.isForBoarding 
                          ? 'Thú cưng đang được bán và giữ dùm. Không thể quản lý yêu cầu nhận nuôi.'
                          : pet.isForSale 
                            ? 'Thú cưng đang được bán. Không thể quản lý yêu cầu nhận nuôi.'
                            : 'Thú cưng đang có dịch vụ giữ dùm. Không thể quản lý yêu cầu nhận nuôi.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Chat với người nhận nuôi (khi đã có yêu cầu Accepted)
            if (pet.adoptionRequests != null &&
                pet.adoptionRequests!.any((r) => r.status == 'Accepted')) ...[
              ElevatedButton.icon(
                onPressed: () {
                  final adopterId = pet.adoptionRequests!
                      .firstWhereOrNull((r) => r.status == 'Accepted')
                      ?.userId;
                  if (adopterId == null) return;
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'otherUserId': adopterId,
                      'petName': pet.name,
                      'chatType': 'adoption',
                    },
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Nhắn tin với người nhận nuôi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Quản lý dịch vụ trao tặng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn có thể quản lý các yêu cầu trao tặng của mình tại đây. Khi có người yêu cầu, bạn sẽ cần xác nhận.',
                    style: TextStyle(
                      color: Colors.orange.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          ] else if (pet.isAdopted) ...[
            FutureBuilder<String?>(
              future: Future.value(context.read<PetProvider>().getMyAdoptionStatusForPet(pet.id!)),
              builder: (context, snapshot) {
                final status = snapshot.data;
                if (status == 'Accepted') {
                  return ElevatedButton.icon(
                    onPressed: () {
                      final ownerId = pet.ownerId;
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'otherUserId': ownerId,
                          'petName': pet.name,
                          'chatType': 'adoption',
                        },
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Nhắn tin với chủ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  );
                }
                return Center(
                  child: Text(
                    'Thú cưng đã được nhận nuôi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ] else ...[
            Center(
              child: Text(
                'Thú cưng không có sẵn để nhận nuôi',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoardingTab(Pet pet, bool isOwner, dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boarding info
          if (pet.isForBoarding) ...[
            _SectionCard(
              title: 'Thông tin giữ dùm',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pet.boardingPricePerDay != null)
                    _RowInfo('Giá/ngày', '${pet.boardingPricePerDay!.toStringAsFixed(0)} VNĐ'),
                  if (pet.boardingStartDate != null)
                    _RowInfo('Ngày bắt đầu', '${pet.boardingStartDate!.day}/${pet.boardingStartDate!.month}/${pet.boardingStartDate!.year}'),
                  if (pet.boardingEndDate != null)
                    _RowInfo('Ngày kết thúc', '${pet.boardingEndDate!.day}/${pet.boardingEndDate!.month}/${pet.boardingEndDate!.year}'),
                  if (pet.boardingDescription != null && pet.boardingDescription!.isNotEmpty)
                    _RowInfo('Mô tả giữ dùm', pet.boardingDescription!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Boarding notes for owner
          if (isOwner && pet.isForBoarding) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.purple.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Lưu ý về dịch vụ giữ dùm:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Khi có người yêu cầu giữ dùm, bạn cần xác nhận trước\n• Sau khi xác nhận, bạn sẽ cần thanh toán để bắt đầu dịch vụ\n• Thú cưng sẽ tạm ẩn trong quá trình giữ dùm',
                    style: TextStyle(
                      color: Colors.purple.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Boarding actions
          if (!isOwner && pet.isForBoarding && !pet.isAdopted) ...[
            // Check if pet is currently being boarded using API response
            FutureBuilder<List<BoardingRequest>>(
              future: _getMyBoardingRequestsForPet(pet.id!),
              builder: (context, snapshot) {
                final isCurrentlyBoarded = pet.isCurrentlyBoarded;
                final currentUserId = currentUser?.id;
                final isCurrentBoardingCustomer = currentUserId != null && 
                    pet.currentBoardingCustomerId != null && 
                    currentUserId == pet.currentBoardingCustomerId;
                    debugPrint('isCurrentBoardingCustomer: $isCurrentBoardingCustomer');
                
                // Check if user has pending boarding request for this pet
                bool hasPendingRequest = false;
                if (snapshot.hasData && currentUserId != null) {
                  hasPendingRequest = snapshot.data!.any((req) => 
                    req.petId == pet.id && 
                    req.customerId == currentUserId && 
                    req.status == 'Pending'
                  );
                }
                              // If current user is the one boarding the pet, show chat button only
                if (isCurrentBoardingCustomer) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pets, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn đang giữ dùm thú cưng này. Có thể chat với chủ thú cưng.',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Chat button for current boarding customer
                      ElevatedButton.icon(
                        onPressed: () async {
                        // Use unified chat logic (same as adoption)
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'otherUserId': pet.ownerId,
                            'petName': pet.name,
                            'chatType': 'boarding',
                          },
                        );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat với chủ thú cưng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  );
                }
                
                // Hide "Đặt lịch" button if pet is currently being boarded by someone else
                if (isCurrentlyBoarded) {
                  // Show toast notification when pet is being boarded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.pets, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Thú cưng này đang được giữ dùm. Vui lòng chọn thú cưng khác.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade600,
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  });
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thú cưng này đang được giữ dùm. Vui lòng chọn thú cưng khác.',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Show "Đã đặt lịch" status if user has pending request
                if (hasPendingRequest) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đã đặt lịch giữ dùm',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Yêu cầu của bạn đang chờ chủ thú cưng xác nhận.',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Show "Đặt lịch" button if pet is available for boarding
                return ElevatedButton.icon(
                  onPressed: () => _showBoardingDialog(pet, currentUser),
                  icon: const Icon(Icons.pets),
                  label: const Text('Đặt lịch giữ dùm'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                );
              },
            ),
          ] else if (isOwner) ...[
            // Owner view - show boarding management options
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Quản lý dịch vụ giữ dùm',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bạn có thể quản lý các yêu cầu giữ dùm thú cưng của mình. Khi có người yêu cầu giữ dùm, bạn sẽ cần xác nhận và thanh toán trước.',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Management button for owner
                if (pet.isForBoarding) ...[
                  ElevatedButton.icon(
                    onPressed: () => _navigateToBoardingRequests(context, pet),
                    icon: const Icon(Icons.pets),
                    label: const Text('Quản lý yêu cầu giữ dùm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Chat button for owner - only show if there's an active boarding request
                FutureBuilder<List<BoardingRequest>>(
                  future: _getBoardingRequestsForPet(pet.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink(); // Hide while loading
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink(); // Hide if error or no data
                    }
                    
                    final requests = snapshot.data!;
                    final activeRequest = requests.where(
                      (req) => req.status == 'InProgress',
                    ).isNotEmpty ? requests.firstWhere(
                      (req) => req.status == 'InProgress',
                    ) : null;
                    
                    // Only show chat button if there's an active boarding request
                    if (activeRequest == null) {
                      return const SizedBox.shrink(); // Hide if no active request
                    }
                    
                    return ElevatedButton.icon(
                      onPressed: () async {
                        // Use unified chat logic (same as adoption)
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'otherUserId': activeRequest.customerId,
                            'petName': pet.name,
                            'chatType': 'boarding',
                          },
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat với người giữ dùm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (pet.isHidden) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thú cưng đang tạm ẩn do có yêu cầu giữ dùm đang chờ xử lý',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ] else if (pet.isAdopted) ...[
            Center(
              child: Text(
              'Thú cưng đã được nhận nuôi',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ] else ...[
            Center(
              child: Text(
              'Thú cưng không có dịch vụ giữ dùm',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Pet pet, bool isOwner, bool canPublish) {
    if (canPublish) {
      return Column(
        children: [
          // Management buttons moved to respective tabs
          
          // Show pet again button if pet is adopted
          if (pet.isAdopted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pets, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Thú cưng đã được bán/nhận nuôi',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thú cưng này đã được bán/nhận nuôi. Bạn có thể hiện lại nếu muốn bán/nhận nuôi lại.',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showPetAgain(pet),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Hiện lại thú cưng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Pet management buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await context.read<PetProvider>().publishPet(pet.id!, !pet.isPublic);
                    if (!mounted) return;
                    if (updated != null) {
                      setState(() => _pet = updated);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(updated.isPublic ? 'Đã công khai' : 'Đã ẩn')));
                    }
                  },
                  icon: Icon(pet.isPublic ? Icons.visibility_off : Icons.visibility),
                  label: Text(pet.isPublic ? 'Ẩn khỏi công khai' : 'Công khai'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _editPet(pet),
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // All adoption logic moved to Adoption tab
      return const SizedBox.shrink();
    }
  }

  void _showBuyDialog(Pet pet, dynamic currentUser, {PriceOffer? acceptedOffer}) {
    // Use accepted offer price if available, otherwise use pet's original price
    final price = acceptedOffer?.offeredAmount ?? pet.price ?? 0;
    final priceController = TextEditingController(text: price.toString());
    final messageController = TextEditingController();
    
    // Price is always locked for buy dialog - no free input allowed
    final isPriceLocked = true;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mua thú cưng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn muốn mua ${pet.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              enabled: !isPriceLocked,
              decoration: InputDecoration(
                labelText: acceptedOffer != null ? 'Giá đã thỏa thuận (VNĐ)' : 'Giá thú cưng (VNĐ)',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.lock, color: Colors.green),
                helperText: acceptedOffer != null 
                    ? 'Giá này đã được thỏa thuận từ đề xuất của bạn' 
                    : 'Giá cố định của thú cưng',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập giá hợp lệ')));
                  return;
                }
                
                final saleRequest = await _saleService.createSaleRequest(
                  petId: pet.id!,
                  buyerId: currentUser.id,
                  amount: price,
                  message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                );
                
                if (!mounted) return;
                Navigator.pop(ctx);
                
                // Check if price matches - if so, go directly to payment
                if (price == pet.price) {
                  // Same price - navigate to payment screen immediately
                  final paymentSuccess = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        type: 'sale',
                        requestId: saleRequest.id,
                        amount: price,
                        description: 'Mua thú cưng ${pet.name}',
                      ),
                    ),
                  );
                  
                  if (paymentSuccess == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yêu cầu mua đã được gửi và thanh toán thành công')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yêu cầu mua đã được gửi. Chờ chủ thú cưng xác nhận để thanh toán')),
                    );
                  }
                } else {
                  // Different price - just send request, wait for seller confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yêu cầu mua đã được gửi. Chờ chủ thú cưng xác nhận')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  void _showPriceOfferDialog(Pet pet, dynamic currentUser) {
    final priceController = TextEditingController(text: pet.price?.toString() ?? '');
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đề xuất giá'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn muốn đề xuất giá cho ${pet.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Giá đề xuất (VNĐ)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập giá hợp lệ')));
                  return;
                }
                
                await _priceOfferService.createPriceOffer(
                  petId: pet.id!,
                  offeredAmount: price,
                  message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                );
                
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đề xuất giá đã được gửi thành công')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Gửi đề xuất'),
          ),
        ],
      ),
    );
  }

  void _showBoardingDialog(Pet pet, dynamic currentUser) {
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = startDate.add(const Duration(days: 7));
    final messageController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đặt lịch giữ dùm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bạn muốn đặt lịch giữ dùm ${pet.name}?'),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        startDate = date;
                        if (endDate.isBefore(startDate)) {
                          endDate = startDate.add(const Duration(days: 1));
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú đặc biệt (tùy chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số điện thoại')));
                    return;
                  }
                  
                  final boardingRequest = await _boardingService.createBoardingRequest(
                    petId: pet.id!,
                    customerId: currentUser.id,
                    startDate: startDate,
                    endDate: endDate,
                    specialInstructions: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                    contactPhone: phoneController.text.trim(),
                    contactAddress: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  );
                  
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  
                  // Navigate to boarding status screen to track the request
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BoardingStatusScreen(
                        boardingRequestId: boardingRequest.id,
                      ),
                    ),
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi yêu cầu giữ dùm. Chờ chủ thú cưng xác nhận và thanh toán.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              },
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSaleRequests(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleRequestsScreen(
          petId: pet.id!,
          petName: pet.name,
        ),
      ),
    );
  }

  void _navigateToBoardingRequests(BuildContext context, Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardingRequestsScreen(
          petId: pet.id!,
          petName: pet.name,
        ),
      ),
    );
  }

  void _editPet(Pet pet) async {
    final updatedPet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPetScreen(pet: pet),
      ),
    );
    
    if (updatedPet != null) {
      setState(() {
        _pet = updatedPet;
      });
    }
  }

  Widget _buildInlinePriceEdit(Pet pet) {
    final priceController = TextEditingController(text: pet.price?.toString() ?? '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Giá bán:', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showPriceEditDialog(pet, priceController),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              Text(
                pet.price != null ? '${pet.price!.toStringAsFixed(0)} VNĐ' : 'Chưa đặt giá',
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
    );
  }

  Widget _buildInlineDescriptionEdit(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Mô tả bán:', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showDescriptionEditDialog(pet),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            pet.saleDescription?.isNotEmpty == true 
                ? pet.saleDescription! 
                : 'Chưa có mô tả bán',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showPriceEditDialog(Pet pet, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa giá bán'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Giá bán (VNĐ)',
            border: OutlineInputBorder(),
            prefixText: '',
            suffixText: ' VNĐ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(controller.text.trim());
              if (price != null && price > 0) {
                final updatedPet = Pet(
                  id: pet.id,
                  name: pet.name,
                  description: pet.description,
                  species: pet.species,
                  breed: pet.breed,
                  ageMonths: pet.ageMonths,
                  gender: pet.gender,
                  imageUrl: pet.imageUrl,
                  ownerId: pet.ownerId,
                  isPublic: pet.isPublic,
                  isAdopted: pet.isAdopted,
                  isHidden: pet.isHidden,
                  isForSale: pet.isForSale,
                  isForBoarding: pet.isForBoarding,
                  price: price,
                  boardingPricePerDay: pet.boardingPricePerDay,
                  boardingDescription: pet.boardingDescription,
                  profile: pet.profile,
                  owner: pet.owner,
                  saleDescription: pet.saleDescription,
                  createdAt: pet.createdAt,
                );
                
                final success = await context.read<PetProvider>().updatePet(updatedPet);
                if (!mounted) return;
                
                if (success) {
                  setState(() {
                    _pet = updatedPet;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật giá bán')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật giá bán thất bại')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập giá hợp lệ')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDescriptionEditDialog(Pet pet) {
    final controller = TextEditingController(text: pet.saleDescription ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa mô tả bán'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Mô tả bán',
            border: OutlineInputBorder(),
            hintText: 'Nhập mô tả về thú cưng khi bán...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedPet = Pet(
                id: pet.id,
                name: pet.name,
                description: pet.description,
                species: pet.species,
                breed: pet.breed,
                ageMonths: pet.ageMonths,
                gender: pet.gender,
                imageUrl: pet.imageUrl,
                ownerId: pet.ownerId,
                isPublic: pet.isPublic,
                isAdopted: pet.isAdopted,
                isHidden: pet.isHidden,
                isForSale: pet.isForSale,
                isForBoarding: pet.isForBoarding,
                price: pet.price,
                boardingPricePerDay: pet.boardingPricePerDay,
                boardingDescription: pet.boardingDescription,
                profile: pet.profile,
                owner: pet.owner,
                saleDescription: controller.text.trim().isEmpty ? null : controller.text.trim(),
                adoptionRequest: pet.adoptionRequest,
                createdAt: pet.createdAt,
              );
              
              final success = await context.read<PetProvider>().updatePet(updatedPet);
              if (!mounted) return;
              
              if (success) {
                setState(() {
                  _pet = updatedPet;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật mô tả bán')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật mô tả bán thất bại')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

}

class _OwnerMapSection extends StatelessWidget {
  final double? ownerLat;
  final double? ownerLng;
  final String? ownerName;
  final String? petGender;
  const _OwnerMapSection({
    required this.ownerLat, 
    required this.ownerLng,
    this.ownerName,
    this.petGender,
  });

  @override
  Widget build(BuildContext context) {
    if (ownerLat == null || ownerLng == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Vị trí chủ nuôi', style: TextStyle(fontWeight: FontWeight.bold)),
            if (ownerName != null) ...[
              const SizedBox(width: 8),
              _buildOwnerInfoChip(),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ll.LatLng(ownerLat!, ownerLng!),
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a','b','c'],
                  userAgentPackageName: 'com.example.petcare',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: ll.LatLng(ownerLat!, ownerLng!),
                    width: 50,
                    height: 50,
                    child: _buildCustomMarker(),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildMapControls(context),
      ],
    );
  }

  Widget _buildOwnerInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 14,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            ownerName ?? 'Chủ nuôi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMarker() {
    // Màu sắc theo giới tính
    Color markerColor;
    IconData genderIcon;
    
    if (petGender?.toLowerCase() == 'male' || petGender?.toLowerCase() == 'đực') {
      markerColor = Colors.blue;
      genderIcon = Icons.male;
    } else if (petGender?.toLowerCase() == 'female' || petGender?.toLowerCase() == 'cái') {
      markerColor = Colors.pink;
      genderIcon = Icons.female;
    } else {
      markerColor = Colors.green;
      genderIcon = Icons.pets;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: markerColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          genderIcon,
          color: markerColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMapControls(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Kiểm tra chiều rộng màn hình
        final isSmallScreen = constraints.maxWidth < 400;
        
        if (isSmallScreen) {
          // Màn hình nhỏ: hiển thị theo cột
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildControlChip(
                      icon: Icons.zoom_in,
                      label: 'Có thể zoom',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildControlChip(
                      icon: Icons.touch_app,
                      label: 'Kéo để di chuyển',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(context),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Dẫn đường'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Màn hình lớn: hiển thị theo hàng
          return Row(
            children: [
              _buildControlChip(
                icon: Icons.zoom_in,
                label: 'Có thể zoom',
              ),
              const SizedBox(width: 8),
              _buildControlChip(
                icon: Icons.touch_app,
                label: 'Kéo để di chuyển',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(context),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Dẫn đường'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildControlChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(BuildContext context) {
    if (ownerLat == null || ownerLng == null) return;
    
    // Kiểm tra xem url_launcher có hoạt động không
    _checkUrlLauncherAvailability(context);
  }

  Future<void> _checkUrlLauncherAvailability(BuildContext context) async {
    try {
      // Test url_launcher bằng cách thử mở một URL đơn giản
      final testUri = Uri.parse('https://www.google.com');
      await canLaunchUrl(testUri);
      
      // Nếu thành công, hiển thị dialog lựa chọn
      _showNavigationOptions(context);
    } catch (e) {
      print('Url launcher not available: $e');
      // Nếu url_launcher không hoạt động, chỉ hiển thị tùy chọn copy tọa độ
      _showFallbackOptions(context);
    }
  }

  void _showFallbackOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dẫn đường'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Plugin dẫn đường không khả dụng. Bạn có thể:'),
              const SizedBox(height: 16),
              _buildNavigationOption(
                context: context,
                icon: Icons.location_on,
                title: 'Sao chép tọa độ',
                subtitle: 'Sao chép tọa độ để sử dụng trong app bản đồ khác',
                onTap: () => _copyCoordinates(context),
              ),
              const SizedBox(height: 8),
              _buildNavigationOption(
                context: context,
                icon: Icons.copy,
                title: 'Sao chép địa chỉ',
                subtitle: 'Sao chép địa chỉ để tìm kiếm thủ công',
                onTap: () => _copyAddress(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyAddress(BuildContext context) async {
    try {
      final address = 'Tọa độ: $ownerLat, $ownerLng';
      await Clipboard.setData(ClipboardData(text: address));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép: $address'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error copying address: $e');
      _showErrorSnackBar(context, 'Không thể sao chép thông tin');
    }
  }

  void _showNavigationOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn phương thức dẫn đường'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavigationOption(
                context: context,
                icon: Icons.map,
                title: 'Google Maps',
                subtitle: kIsWeb 
                    ? 'Mở trong trình duyệt web'
                    : 'Mở app Google Maps (nếu có) hoặc web',
                onTap: () => _launchGoogleMaps(context),
              ),
              const SizedBox(height: 8),
              if (!kIsWeb && Platform.isIOS) ...[
                _buildNavigationOption(
                  context: context,
                  icon: Icons.navigation,
                  title: 'Apple Maps',
                  subtitle: 'Mở trong ứng dụng Apple Maps',
                  onTap: () => _launchAppleMaps(context),
                ),
                const SizedBox(height: 8),
              ],
              _buildNavigationOption(
                context: context,
                icon: Icons.location_on,
                title: 'Tọa độ GPS',
                subtitle: 'Sao chép tọa độ để sử dụng',
                onTap: () => _copyCoordinates(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    try {
      if (kIsWeb) {
        // Trên web, mở trực tiếp Google Maps web
        await _launchGoogleMapsWeb(context);
      } else {
        // Trên mobile, thử mở app trước, nếu không có thì mở web
        await _launchGoogleMapsApp(context);
      }
    } catch (e) {
      print('Error launching Google Maps: $e');
      // Nếu có lỗi MissingPluginException, thử copy tọa độ
      if (e.toString().contains('MissingPluginException')) {
        _showErrorSnackBar(context, 'Plugin không khả dụng. Đang sao chép tọa độ...');
        await _copyCoordinates(context);
      } else {
        _showErrorSnackBar(context, 'Không thể mở Google Maps');
      }
    }
  }

  Future<void> _launchGoogleMapsApp(BuildContext context) async {
    try {
      // Thử mở Google Maps app trước
      final googleMapsAppUrl = 'comgooglemaps://?daddr=$ownerLat,$ownerLng&directionsmode=driving';
      final Uri appUri = Uri.parse(googleMapsAppUrl);
      
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Nếu không có app, thử mở trong trình duyệt
      await _launchGoogleMapsWeb(context);
    } catch (e) {
      print('Error launching Google Maps app: $e');
      // Nếu có lỗi MissingPluginException, thử copy tọa độ
      if (e.toString().contains('MissingPluginException')) {
        _showErrorSnackBar(context, 'Plugin không khả dụng. Đang sao chép tọa độ...');
        await _copyCoordinates(context);
      } else {
        // Fallback to web
        await _launchGoogleMapsWeb(context);
      }
    }
  }

  Future<void> _launchGoogleMapsWeb(BuildContext context) async {
    try {
      final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$ownerLat,$ownerLng&travelmode=driving';
      final Uri uri = Uri.parse(googleMapsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Error launching Google Maps web: $e');
      // Nếu có lỗi MissingPluginException, thử copy tọa độ
      if (e.toString().contains('MissingPluginException')) {
        _showErrorSnackBar(context, 'Plugin không khả dụng. Đang sao chép tọa độ...');
        await _copyCoordinates(context);
      } else {
        _showErrorSnackBar(context, 'Không thể mở Google Maps');
      }
    }
  }

  Future<void> _launchAppleMaps(BuildContext context) async {
    try {
      // Chỉ hoạt động trên iOS
      final appleMapsUrl = 'http://maps.apple.com/?daddr=$ownerLat,$ownerLng&dirflg=d';
      final Uri uri = Uri.parse(appleMapsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Apple Maps không khả dụng trên thiết bị này');
      }
    } catch (e) {
      print('Error launching Apple Maps: $e');
      // Nếu có lỗi MissingPluginException, thử copy tọa độ
      if (e.toString().contains('MissingPluginException')) {
        _showErrorSnackBar(context, 'Plugin không khả dụng. Đang sao chép tọa độ...');
        await _copyCoordinates(context);
      } else {
        _showErrorSnackBar(context, 'Không thể mở Apple Maps');
      }
    }
  }

  Future<void> _copyCoordinates(BuildContext context) async {
    try {
      final coordinates = '$ownerLat, $ownerLng';
      // Sử dụng Clipboard để copy tọa độ
      await Clipboard.setData(ClipboardData(text: coordinates));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép tọa độ: $coordinates'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error copying coordinates: $e');
      _showErrorSnackBar(context, 'Không thể sao chép tọa độ');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  const _RowInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


