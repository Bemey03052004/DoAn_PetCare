import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/sale_service.dart';
import '../services/boarding_service.dart';

class PaymentScreen extends StatefulWidget {
  final String type; // 'sale' or 'boarding'
  final int requestId;
  final double amount;
  final String description;

  const PaymentScreen({
    super.key,
    required this.type,
    required this.requestId,
    required this.amount,
    required this.description,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;
  
  late SaleService _saleService;
  late BoardingService _boardingService;

  final List<String> _paymentMethods = [
    'Cash',
    'BankTransfer',
    'Momo',
    'ZaloPay',
    'VNPay',
  ];

  @override
  void initState() {
    super.initState();
    _saleService = SaleService(context.read<AuthProvider>().authService);
    _boardingService = BoardingService(context.read<AuthProvider>().authService);
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.type == 'sale') {
        // Create payment
        final paymentResponse = await _saleService.createPayment(
          saleRequestId: widget.requestId,
          paymentMethod: _selectedPaymentMethod,
          transactionId: _transactionIdController.text.trim().isEmpty 
              ? null 
              : _transactionIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
        
        // Update payment status to Completed
        final paymentId = paymentResponse['id'] as int;
        await _saleService.updatePaymentStatus(
          paymentId: paymentId,
          status: 'Completed',
          referenceId: _transactionIdController.text.trim().isEmpty 
              ? null 
              : _transactionIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
      } else if (widget.type == 'boarding') {
        await _boardingService.createBoardingPayment(
          boardingRequestId: widget.requestId,
          paymentMethod: _selectedPaymentMethod,
          transactionId: _transactionIdController.text.trim().isEmpty 
              ? null 
              : _transactionIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
        );
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán đã được xác nhận thành công')),
      );
      
      Navigator.pop(context, true); // Return success
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi thanh toán: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán ${widget.type == 'sale' ? 'mua bán' : 'giữ dùm'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment summary card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin thanh toán',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số tiền:', style: TextStyle(fontSize: 16)),
                          Text(
                            '${widget.amount.toStringAsFixed(0)} VNĐ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Loại:', style: TextStyle(fontSize: 16)),
                          Text(
                            widget.type == 'sale' ? 'Mua bán thú cưng' : 'Giữ dùm thú cưng',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mô tả:', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment method selection
              Text(
                'Phương thức thanh toán',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ..._paymentMethods.map((method) => RadioListTile<String>(
                title: Text(_getPaymentMethodName(method)),
                subtitle: Text(_getPaymentMethodDescription(method)),
                value: method,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value!);
                },
              )),
              
              const SizedBox(height: 24),
              
              // Transaction ID (for electronic payments)
              if (_selectedPaymentMethod != 'Cash') ...[
                TextFormField(
                  controller: _transactionIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch',
                    hintText: 'Nhập mã giao dịch từ ứng dụng thanh toán',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt),
                  ),
                  validator: (value) {
                    if (_selectedPaymentMethod != 'Cash' && 
                        (value == null || value.trim().isEmpty)) {
                      return 'Vui lòng nhập mã giao dịch';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'Thêm ghi chú cho giao dịch này',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // Payment button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Payment instructions
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Hướng dẫn thanh toán',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPaymentInstructions(_selectedPaymentMethod),
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'Cash': return 'Tiền mặt';
      case 'BankTransfer': return 'Chuyển khoản ngân hàng';
      case 'Momo': return 'Ví MoMo';
      case 'ZaloPay': return 'Ví ZaloPay';
      case 'VNPay': return 'VNPay';
      default: return method;
    }
  }

  String _getPaymentMethodDescription(String method) {
    switch (method) {
      case 'Cash': return 'Thanh toán trực tiếp khi giao nhận';
      case 'BankTransfer': return 'Chuyển khoản qua ngân hàng';
      case 'Momo': return 'Thanh toán qua ví MoMo';
      case 'ZaloPay': return 'Thanh toán qua ví ZaloPay';
      case 'VNPay': return 'Thanh toán qua VNPay';
      default: return '';
    }
  }

  String _getPaymentInstructions(String method) {
    switch (method) {
      case 'Cash':
        return 'Thanh toán bằng tiền mặt khi giao nhận thú cưng. Đảm bảo mang đủ tiền và kiểm tra thú cưng trước khi thanh toán.';
      case 'BankTransfer':
        return 'Chuyển khoản đến tài khoản ngân hàng của người bán/chủ nuôi. Vui lòng ghi rõ mã giao dịch và nội dung chuyển khoản.';
      case 'Momo':
        return 'Thanh toán qua ứng dụng MoMo. Quét mã QR hoặc chuyển tiền đến số điện thoại của người bán/chủ nuôi.';
      case 'ZaloPay':
        return 'Thanh toán qua ứng dụng ZaloPay. Quét mã QR hoặc chuyển tiền đến số điện thoại của người bán/chủ nuôi.';
      case 'VNPay':
        return 'Thanh toán qua cổng VNPay. Sử dụng thẻ ATM, thẻ tín dụng hoặc ví điện tử được hỗ trợ.';
      default:
        return 'Vui lòng thực hiện thanh toán theo hướng dẫn của phương thức đã chọn.';
    }
  }
}
