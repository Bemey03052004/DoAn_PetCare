import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().verifyEmail(
        widget.email,
        _codeController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email đã được xác thực thành công! Bạn có thể đăng nhập ngay bây giờ.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Xử lý các loại lỗi cụ thể
        if (errorMessage.contains('Invalid or expired verification code')) {
          _errorMessage = 'Mã xác thực không hợp lệ hoặc đã hết hạn. Vui lòng nhấn "Gửi lại mã" để nhận mã mới.';
        } else if (errorMessage.contains('Invalid')) {
          _errorMessage = 'Mã xác thực không đúng. Vui lòng kiểm tra lại số đã nhập.';
        } else if (errorMessage.contains('expired')) {
          _errorMessage = 'Mã xác thực đã hết hạn (15 phút). Vui lòng nhấn "Gửi lại mã" để nhận mã mới.';
        } else if (errorMessage.contains('not found')) {
          _errorMessage = 'Không tìm thấy mã xác thực. Vui lòng yêu cầu mã mới.';
        } else {
          _errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại hoặc yêu cầu mã mới.';
        }
        
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().resendVerificationCode(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã xác thực mới đã được gửi! Vui lòng kiểm tra email.'),
            backgroundColor: Colors.green,
          ),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể gửi mã mới. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo và tiêu đề
                  const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Xác thực email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chúng tôi đã gửi mã xác thực đến:\n${widget.email}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '⏰ Mã có hiệu lực trong 15 phút',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nếu chưa nhận được mã, vui lòng kiểm tra hộp thư spam hoặc nhấn "Gửi lại mã".',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Form nhập mã xác thực
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    onChanged: (value) {
                      // Clear error message khi người dùng nhập lại
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mã xác thực',
                      hintText: 'Nhập mã 6 chữ số',
                      prefixIcon: const Icon(Icons.security),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mã xác thực';
                      }
                      if (value.length != 6) {
                        return 'Mã xác thực phải có 6 chữ số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Hiển thị thông báo lỗi
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.contains('hết hạn') 
                              ? Icons.access_time 
                              : Icons.error_outline, 
                            color: Colors.red[700], 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nút xác thực
                  GradientButton(
                    text: 'Xác thực email',
                    onPressed: _isLoading ? null : _verifyEmail,
                    isLoading: _isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),

                  // Nút gửi lại mã
                  TextButton(
                    onPressed: _isResending ? null : _resendVerificationCode,
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Gửi lại mã',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Nút quay lại đăng nhập
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
