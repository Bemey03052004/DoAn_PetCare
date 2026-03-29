import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/create_pet_request.dart';
import '../models/species.dart';
import '../services/species_service.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';

class CreatePetScreen extends StatefulWidget {
  const CreatePetScreen({super.key});

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _ageMonths = TextEditingController(text: '0');
  final _imageUrl = TextEditingController();
  final _description = TextEditingController();
  final _personality = TextEditingController();
  final _favoriteFood = TextEditingController();
  final _hobbies = TextEditingController();
  final _story = TextEditingController();
  final _socialImage = TextEditingController();
  final _price = TextEditingController();
  final _saleDescription = TextEditingController();
  final _boardingPricePerDay = TextEditingController();
  final _boardingDescription = TextEditingController();
  final List<DateTime> _vaxDates = [];
  String _speciesValue = 'Dog';
  List<Species> _speciesList = const [];
  bool _loadingSpecies = true;
  String _genderValue = 'Male';
  bool _isPublic = true;
  bool _isForSale = false;
  bool _isForBoarding = false;
  DateTime? _boardingStartDate;
  DateTime? _boardingEndDate;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  Future<void> _loadSpecies() async {
    try {
      final list = await SpeciesService().getAll();
      setState(() {
        _speciesList = list.where((s) => s.isActive).toList();
        if (_speciesList.isNotEmpty) {
          // Nếu giá trị hiện tại không nằm trong list, set theo phần tử đầu
          if (!_speciesList.any((s) => s.name == _speciesValue)) {
            _speciesValue = _speciesList.first.name;
          }
        }
        _loadingSpecies = false;
      });
    } catch (_) {
      setState(() { _loadingSpecies = false; });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _ageMonths.dispose();
    _imageUrl.dispose();
    _description.dispose();
    _personality.dispose();
    _favoriteFood.dispose();
    _hobbies.dispose();
    _story.dispose();
    _socialImage.dispose();
    _price.dispose();
    _saleDescription.dispose();
    _boardingPricePerDay.dispose();
    _boardingDescription.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập.')));
      return;
    }
    final req = CreatePetRequest(
      name: _name.text.trim(),
      species: _speciesValue,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      gender: _genderValue,
      ageMonths: int.tryParse(_ageMonths.text.trim()) ?? 0,
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      ownerId: user.id,
      isPublic: _isPublic,
      isForSale: _isForSale,
      price: _isForSale ? double.tryParse(_price.text.trim()) : null,
      saleDescription: _isForSale && _saleDescription.text.trim().isNotEmpty ? _saleDescription.text.trim() : null,
      isForBoarding: _isForBoarding,
      boardingPricePerDay: _isForBoarding ? double.tryParse(_boardingPricePerDay.text.trim()) : null,
      boardingStartDate: _isForBoarding ? _boardingStartDate : null,
      boardingEndDate: _isForBoarding ? _boardingEndDate : null,
      boardingDescription: _isForBoarding && _boardingDescription.text.trim().isNotEmpty ? _boardingDescription.text.trim() : null,
      personality: _personality.text.trim().isEmpty ? null : _personality.text.trim(),
      favoriteFood: _favoriteFood.text.trim().isEmpty ? null : _favoriteFood.text.trim(),
      hobbies: _hobbies.text.trim().isEmpty ? null : _hobbies.text.trim(),
      story: _story.text.trim().isEmpty ? null : _story.text.trim(),
      socialImage: _socialImage.text.trim().isEmpty ? null : _socialImage.text.trim(),
      vaccinationDates: _vaxDates,
    );
    final provider = context.read<PetProvider>();
    final created = await provider.createPet(req);
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo thú cưng thành công.')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Lỗi tạo thú cưng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PetProvider>().isLoading;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade400,
                      Colors.blue.shade400,
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
                            const Text(
                              'Tạo thú cưng mới',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionCard(
                      title: 'Thông tin cơ bản',
                      icon: Icons.pets,
                      color: Colors.blue,
                      children: [
                        _buildModernTextField(
                          controller: _name,
                          label: 'Tên thú cưng',
                          hint: 'Nhập tên thú cưng',
                          icon: Icons.pets,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _loadingSpecies
                                  ? const Center(child: CircularProgressIndicator())
                                  : _buildModernDropdown(
                                      value: _speciesValue,
                                      label: 'Loài',
                                      icon: Icons.category,
                                      items: _speciesList.isNotEmpty
                                          ? _speciesList
                                              .map((s) => DropdownMenuItem(
                                                    value: s.name,
                                                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                                                  ))
                                              .toList()
                                          : const [
                                              DropdownMenuItem(
                                                value: 'Dog',
                                                child: Text('🐕 Chó', overflow: TextOverflow.ellipsis),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Cat',
                                                child: Text('🐱 Mèo', overflow: TextOverflow.ellipsis),
                                              ),
                                              DropdownMenuItem(
                                                value: 'Other',
                                                child: Text('🐾 Khác', overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                      onChanged: (v) => setState(() => _speciesValue = v ?? _speciesValue),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernDropdown(
                                value: _genderValue,
                                label: 'Giới tính',
                                icon: Icons.wc,
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('♂️ Đực', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Female', child: Text('♀️ Cái', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Unknown', child: Text('❓ Không rõ', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (v) => setState(() => _genderValue = v ?? 'Unknown'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: _breed,
                                label: 'Giống',
                                hint: 'VD: Golden Retriever',
                                icon: Icons.pets,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernTextField(
                                controller: _ageMonths,
                                label: 'Tuổi (tháng)',
                                hint: '0',
                                icon: Icons.cake,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Image Section
                    _buildSectionCard(
                      title: 'Ảnh thú cưng',
                      icon: Icons.image,
                      color: Colors.purple,
                      children: [
                        _buildModernTextField(
                          controller: _imageUrl,
                          label: 'URL ảnh chính',
                          hint: 'https://example.com/pet-image.jpg',
                          icon: Icons.link,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _socialImage,
                          label: 'URL ảnh xã hội',
                          hint: 'https://example.com/social-image.jpg',
                          icon: Icons.photo_library,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _description,
                          label: 'Mô tả',
                          hint: 'Mô tả về thú cưng của bạn...',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile Section
                    _buildSectionCard(
                      title: 'Hồ sơ cá nhân',
                      icon: Icons.person,
                      color: Colors.orange,
                      children: [
                        _buildModernTextField(
                          controller: _personality,
                          label: 'Tính cách',
                          hint: 'VD: Thân thiện, năng động',
                          icon: Icons.mood,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _favoriteFood,
                          label: 'Món yêu thích',
                          hint: 'VD: Thịt bò, cá',
                          icon: Icons.restaurant,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _hobbies,
                          label: 'Sở thích',
                          hint: 'VD: Chạy nhảy, chơi bóng',
                          icon: Icons.sports_soccer,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _story,
                          label: 'Câu chuyện',
                          hint: 'Chia sẻ câu chuyện về thú cưng...',
                          icon: Icons.book,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Visibility Settings
                    _buildSectionCard(
                      title: 'Cài đặt hiển thị',
                      icon: Icons.visibility,
                      color: Colors.teal,
                      children: [
                        _buildModernSwitch(
                          value: _isPublic,
                          title: 'Công khai ngay',
                          subtitle: 'Hiển thị thú cưng cho mọi người',
                          icon: Icons.public,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Selling Section
                    _buildSectionCard(
                      title: 'Bán thú cưng',
                      icon: Icons.sell,
                      color: Colors.green,
                      children: [
                        _buildModernSwitch(
                          value: _isForSale,
                          title: 'Đăng bán thú cưng',
                          subtitle: 'Cho phép người khác mua thú cưng này',
                          icon: Icons.shopping_cart,
                          onChanged: (value) {
                            setState(() {
                              _isForSale = value;
                              if (!value) {
                                _price.clear();
                                _saleDescription.clear();
                              }
                            });
                          },
                        ),
                        if (_isForSale) ...[
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _price,
                            label: 'Giá bán (VNĐ)',
                            hint: '1000000',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_isForSale && (value == null || value.isEmpty)) {
                                return 'Vui lòng nhập giá bán';
                              }
                              if (_isForSale && value != null && value.isNotEmpty) {
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Giá bán phải là số dương';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _saleDescription,
                            label: 'Mô tả bán hàng',
                            hint: 'Mô tả về việc bán thú cưng...',
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Boarding Section
                    _buildSectionCard(
                      title: 'Dịch vụ giữ hộ',
                      icon: Icons.hotel,
                      color: Colors.indigo,
                      children: [
                        _buildModernSwitch(
                          value: _isForBoarding,
                          title: 'Cung cấp dịch vụ giữ hộ',
                          subtitle: 'Cho phép người khác gửi thú cưng để giữ hộ',
                          icon: Icons.hotel,
                          onChanged: (value) {
                            setState(() {
                              _isForBoarding = value;
                              if (!value) {
                                _boardingPricePerDay.clear();
                                _boardingDescription.clear();
                                _boardingStartDate = null;
                                _boardingEndDate = null;
                              }
                            });
                          },
                        ),
                        if (_isForBoarding) ...[
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _boardingPricePerDay,
                            label: 'Giá giữ hộ/ngày (VNĐ)',
                            hint: '50000',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_isForBoarding && (value == null || value.isEmpty)) {
                                return 'Vui lòng nhập giá giữ hộ/ngày';
                              }
                              if (_isForBoarding && value != null && value.isNotEmpty) {
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Giá giữ hộ phải là số dương';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _boardingDescription,
                            label: 'Mô tả dịch vụ giữ hộ',
                            hint: 'Mô tả về dịch vụ giữ hộ...',
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDatePicker(
                                  title: 'Ngày bắt đầu',
                                  date: _boardingStartDate,
                                  icon: Icons.calendar_today,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _boardingStartDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _boardingStartDate = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDatePicker(
                                  title: 'Ngày kết thúc',
                                  date: _boardingEndDate,
                                  icon: Icons.event,
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _boardingEndDate ?? (_boardingStartDate ?? DateTime.now()),
                                      firstDate: _boardingStartDate ?? DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _boardingEndDate = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Vaccination Section
                    _buildSectionCard(
                      title: 'Lịch tiêm phòng',
                      icon: Icons.medical_services,
                      color: Colors.red,
                      children: [
                        if (_vaxDates.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.medical_services, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có lịch tiêm phòng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thêm ngày tiêm phòng cho thú cưng',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _vaxDates.map((date) => Chip(
                              label: Text('${date.day}/${date.month}/${date.year}'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => setState(() => _vaxDates.remove(date)),
                            )).toList(),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: now.subtract(const Duration(days: 0)),
                                lastDate: now.add(const Duration(days: 365 * 3)),
                              );
                              if (picked != null) {
                                setState(() => _vaxDates.add(picked));
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm ngày tiêm phòng'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle),
                        label: Text(
                          isLoading ? 'Đang tạo thú cưng...' : 'Tạo thú cưng',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
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
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildModernSwitch({
    required bool value,
    required String title,
    required String subtitle,
    required IconData icon,
    required void Function(bool) onChanged,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 12),
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
                    date != null 
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Chọn ngày',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null ? Colors.black : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}


