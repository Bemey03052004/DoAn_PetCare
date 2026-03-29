import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/biometric_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _populateForm();
  }
  
  void _populateForm() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user != null) {
        try {
          final userData = {
            'fullName': _fullNameController.text,
            'email': user.email, // Giữ nguyên email
            'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
            'address': _addressController.text.isEmpty ? null : _addressController.text,
            'latitude': user.latitude, // Giữ nguyên latitude
            'longitude': user.longitude, // Giữ nguyên longitude
            'roles': user.roles, // Giữ nguyên roles
          };
          
          final updatedUser = await userProvider.updateProfile(userData);
          
          if (updatedUser != null) {
            // Update the auth provider with the updated user
            authProvider.updateCurrentUser(updatedUser);
            
            setState(() {
              _isEditing = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.purple.shade400,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hồ sơ cá nhân',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quản lý thông tin tài khoản',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.save : Icons.edit,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveChanges();
                                } else {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                }
                              },
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

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // User Avatar Section
                  _buildAvatarSection(user),
                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 24),

                  // Account Information Section
                  _buildAccountInfoSection(user),
                  const SizedBox(height: 24),

                  // Security Section
                  _buildSecuritySection(user),
                  const SizedBox(height: 24),

                  // Admin Section
                  if (user.isAdmin) ...[
                    _buildAdminSection(),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons Section
                  _buildActionButtonsSection(authProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.isAdmin ? 'ADMIN' : 'USER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: user.isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: 'Thông tin cá nhân',
      icon: Icons.person,
      color: Colors.blue,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildModernTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                hint: 'Nhập họ và tên của bạn',
                icon: Icons.person_outline,
                readOnly: !_isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                hint: 'Nhập số điện thoại',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _addressController,
                label: 'Địa chỉ',
                hint: 'Nhập địa chỉ của bạn',
                icon: Icons.location_on,
                maxLines: 2,
                readOnly: !_isEditing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection(user) {
    return _buildSectionCard(
      title: 'Thông tin tài khoản',
      icon: Icons.account_circle,
      color: Colors.green,
      children: [
        _buildInfoRow(
          icon: Icons.email,
          title: 'Email',
          value: user.email,
          isLocked: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.security,
          title: 'Vai trò',
          value: user.roles.join(', '),
          isLocked: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          icon: Icons.calendar_today,
          title: 'Thành viên từ',
          value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
          isLocked: true,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(user) {
    return _buildSectionCard(
      title: 'Bảo mật',
      icon: Icons.security,
      color: Colors.orange,
      children: [
        Consumer<BiometricProvider>(
          builder: (context, biometricProvider, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: biometricProvider.canUseBiometric 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      biometricProvider.canUseBiometric 
                        ? Icons.fingerprint 
                        : Icons.fingerprint_outlined,
                      color: biometricProvider.canUseBiometric 
                        ? Colors.blue 
                        : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sử dụng ${biometricProvider.biometricTypeName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          biometricProvider.isBiometricEnabled 
                            ? 'Đã bật xác thực sinh trắc học'
                            : 'Chưa bật xác thực sinh trắc học',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: biometricProvider.isBiometricEnabled,
                    onChanged: biometricProvider.canUseBiometric 
                      ? (value) async {
                          if (value) {
                            final authenticated = await biometricProvider.authenticateWithBiometric();
                            if (authenticated) {
                              await biometricProvider.toggleBiometric();
                              await biometricProvider.saveBiometricCredentials(
                                user.email, 
                                'current_password'
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã bật ${biometricProvider.biometricTypeName}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            await biometricProvider.toggleBiometric();
                            await biometricProvider.clearBiometricCredentials();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã tắt xác thực sinh trắc học'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      : null,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return _buildSectionCard(
      title: 'Quản trị viên',
      icon: Icons.admin_panel_settings,
      color: Colors.red,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/admin/users'),
            icon: const Icon(Icons.people),
            label: const Text('Quản lý người dùng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsSection(authProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login-sessions'),
            icon: const Icon(Icons.devices),
            label: const Text('Quản lý phiên đăng nhập'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: readOnly 
          ? const Icon(Icons.lock, size: 16, color: Colors.grey)
          : null,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            const Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
