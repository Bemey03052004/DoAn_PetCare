import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/location_helper.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/address_dropdown.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  double? _latitude;
  double? _longitude;
  
  // Address selection
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;
  String? _selectedProvinceName;
  String? _selectedDistrictName;
  String? _selectedWardName;
  String? _provinceError;
  String? _districtError;
  String? _wardError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _onProvinceChanged(String? provinceCode, String? provinceName) {
    setState(() {
      _selectedProvince = provinceCode;
      _selectedProvinceName = provinceName;
      _selectedDistrict = null;
      _selectedDistrictName = null;
      _selectedWard = null;
      _selectedWardName = null;
      _provinceError = null;
      _districtError = null;
      _wardError = null;
    });
  }

  void _onDistrictChanged(String? districtCode, String? districtName) {
    setState(() {
      _selectedDistrict = districtCode;
      _selectedDistrictName = districtName;
      _selectedWard = null;
      _selectedWardName = null;
      _districtError = null;
      _wardError = null;
    });
  }

  void _onWardChanged(String? wardCode, String? wardName) {
    setState(() {
      _selectedWard = wardCode;
      _selectedWardName = wardName;
      _wardError = null;
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      final pos = await LocationHelper.determinePosition();
      if (pos != null) {
        if (!mounted) return;
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _latitude = null;
          _longitude = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  String? _validateAddress() {
    if (_selectedProvince == null) {
      return 'Vui lòng chọn tỉnh/thành phố';
    }
    if (_selectedDistrict == null) {
      return 'Vui lòng chọn quận/huyện';
    }
    if (_selectedWard == null) {
      return 'Vui lòng chọn phường/xã';
    }
    return null;
  }

  String _getSelectedProvinceName() {
    return _selectedProvinceName ?? '';
  }

  String _getSelectedDistrictName() {
    return _selectedDistrictName ?? '';
  }

  String _getSelectedWardName() {
    return _selectedWardName ?? '';
  }


  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate address selection
    final addressError = _validateAddress();
    if (addressError != null) {
      setState(() {
        _provinceError = _selectedProvince == null ? 'Vui lòng chọn tỉnh/thành phố' : null;
        _districtError = _selectedDistrict == null ? 'Vui lòng chọn quận/huyện' : null;
        _wardError = _selectedWard == null ? 'Vui lòng chọn phường/xã' : null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Lấy tọa độ hiện tại (nếu chưa có)
    if (_latitude == null || _longitude == null) {
      await _getCurrentPosition();
    }

    // Tạo địa chỉ đầy đủ từ tên đường/số nhà + dropdown
    final streetAddress = _address.text.trim();
    final wardName = _getSelectedWardName();
    final districtName = _getSelectedDistrictName();
    final provinceName = _getSelectedProvinceName();
    
    final fullAddress = streetAddress.isNotEmpty 
        ? '$streetAddress, $wardName, $districtName, $provinceName'
        : '$wardName, $districtName, $provinceName';

    final payload = {
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'confirmPassword': _confirm.text,
      'phone': _phone.text.trim(),
      'address': fullAddress,
      'latitude': _latitude,
      'longitude': _longitude,
    };

    final res =
        await Provider.of<AuthProvider>(context, listen: false).register(payload);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng xác thực email.')),
      );
      Navigator.pushReplacementNamed(context, '/verify-email', arguments: _email.text);
    } else {
      // xử lý lỗi (messages / fieldErrors theo AuthService mới)
      final msgs =
          (res['messages'] as List?)?.map((e) => e.toString()).toList() ?? [];
      setState(() {
        _error = msgs.isNotEmpty
            ? msgs.join('\n')
            : (res['message']?.toString() ?? 'Registration failed');
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _locationStatus() {
    if (_latitude != null && _longitude != null) {
      return Text(
          'Location: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
          style: const TextStyle(color: Colors.green));
    } else {
      return const Text('Location: not available',
          style: TextStyle(color: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đăng ký tài khoản',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo tài khoản để bắt đầu sử dụng PetCare',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Full Name
                    CustomTextField(
                      controller: _fullName,
                      labelText: 'Họ và tên',
                      hintText: 'Nhập họ và tên của bạn',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    CustomTextField(
                      controller: _email,
                      labelText: 'Email',
                      hintText: 'Nhập email của bạn',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    CustomTextField(
                      controller: _phone,
                      labelText: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại (tùy chọn)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password
                    CustomTextField(
                      controller: _password,
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      onSuffixIconTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    CustomTextField(
                      controller: _confirm,
                      labelText: 'Xác nhận mật khẩu',
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      onSuffixIconTap: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _password.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    CustomTextField(
                      controller: _address,
                      labelText: 'Tên đường, số nhà',
                      hintText: 'Ví dụ: 123 Nguyễn Văn A, Phường 1',
                      prefixIcon: Icons.home,
                      maxLines: 1,
                      validator: (value) {
                        // Tùy chọn - không bắt buộc nhập
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chọn địa chỉ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AddressDropdown(
                            selectedProvince: _selectedProvince,
                            selectedDistrict: _selectedDistrict,
                            selectedWard: _selectedWard,
                            onProvinceChanged: _onProvinceChanged,
                            onDistrictChanged: _onDistrictChanged,
                            onWardChanged: _onWardChanged,
                            provinceError: _provinceError,
                            districtError: _districtError,
                            wardError: _wardError,
                          ),
                        ],
                      ),
                    ),
                    
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    GradientButton(
                      text: 'Đăng ký',
                      onPressed: _isLoading ? null : _register,
                      isLoading: _isLoading,
                      icon: Icons.person_add,
                      width: double.infinity,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Đăng nhập ngay',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
