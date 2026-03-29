import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../models/species.dart';
import '../services/species_service.dart';
import '../providers/pet_provider.dart';
import '../widgets/custom_text_field.dart';

class EditPetScreen extends StatefulWidget {
  final Pet pet;

  const EditPetScreen({super.key, required this.pet});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _ageController;
  late TextEditingController _breedController;
  late TextEditingController _priceController;
  late TextEditingController _boardingPriceController;
  late TextEditingController _specialInstructionsController;

  String _selectedSpecies = '';
  String _selectedGender = '';
  bool _isForSale = false;
  bool _isForBoarding = false;
  bool _isLoading = false;
  List<Species> _speciesList = [];
  bool _loadingSpecies = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSpecies();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.pet.name);
    _descriptionController = TextEditingController(text: widget.pet.description ?? '');
    _ageController = TextEditingController(text: widget.pet.ageMonths.toString());
    _breedController = TextEditingController(text: widget.pet.breed ?? '');
    _priceController = TextEditingController(text: widget.pet.price?.toString() ?? '');
    _boardingPriceController = TextEditingController(text: widget.pet.boardingPricePerDay?.toString() ?? '');
    _specialInstructionsController = TextEditingController(text: widget.pet.boardingDescription ?? '');

    // Map species from English to Vietnamese if needed
    _selectedSpecies = _mapSpeciesToVietnamese(widget.pet.species);
    _selectedGender = _mapGenderToVietnamese(widget.pet.gender ?? '');
    _isForSale = widget.pet.isForSale;
    _isForBoarding = widget.pet.isForBoarding;
  }

  Future<void> _loadSpecies() async {
    try {
      final list = await SpeciesService().getAll();
      setState(() {
        _speciesList = list.where((s) => s.isActive).toList();
        _loadingSpecies = false;
      });
    } catch (_) {
      setState(() { _loadingSpecies = false; });
    }
  }

  String _mapSpeciesToVietnamese(String species) {
    // Since we're now using API data directly, species names are already in the correct format
    // No need for mapping - just return as is
    return species;
  }

  String _mapSpeciesToEnglish(String species) {
    // Since we're now using API data directly, species names are already in the correct format
    // No need for mapping - just return as is
    return species;
  }

  String _mapGenderToVietnamese(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Đực';
      case 'female':
        return 'Cái';
      default:
        // If already in Vietnamese or unknown, return as is
        return gender;
    }
  }

  String _mapGenderToEnglish(String gender) {
    switch (gender) {
      case 'Đực':
        return 'Male';
      case 'Cái':
        return 'Female';
      default:
        // If already in English or unknown, return as is
        return gender;
    }
  }

  String? _getValidSpeciesValue() {
    if (_loadingSpecies || _speciesList.isEmpty) {
      return null;
    }
    if (_selectedSpecies.isEmpty || !_speciesList.any((s) => s.name == _selectedSpecies)) {
      return _speciesList.first.name; // Return first available species if current is invalid
    }
    return _selectedSpecies;
  }

  String? _getValidGenderValue() {
    const validGenders = ['Đực', 'Cái'];
    if (_selectedGender.isEmpty || !validGenders.contains(_selectedGender)) {
      return null; // Return null if invalid, which will show placeholder
    }
    return _selectedGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _breedController.dispose();
    _priceController.dispose();
    _boardingPriceController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedPet = Pet(
        id: widget.pet.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        species: _mapSpeciesToEnglish(_selectedSpecies),
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        ageMonths: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender.isEmpty ? null : _mapGenderToEnglish(_selectedGender),
        imageUrl: widget.pet.imageUrl,
        ownerId: widget.pet.ownerId,
        isPublic: widget.pet.isPublic,
        isAdopted: widget.pet.isAdopted,
        isHidden: widget.pet.isHidden,
        isForSale: _isForSale,
        isForBoarding: _isForBoarding,
        price: _isForSale ? double.tryParse(_priceController.text.trim()) : null,
        boardingPricePerDay: _isForBoarding ? double.tryParse(_boardingPriceController.text.trim()) : null,
        boardingDescription: _specialInstructionsController.text.trim().isEmpty ? null : _specialInstructionsController.text.trim(),
        profile: widget.pet.profile,
        owner: widget.pet.owner,
        createdAt: widget.pet.createdAt,
      );

      final success = await context.read<PetProvider>().updatePet(updatedPet);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin thú cưng thành công')),
        );
        Navigator.pop(context, updatedPet);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
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
        title: const Text('Chỉnh sửa thú cưng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionCard(
                'Thông tin cơ bản',
                [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Tên thú cưng *',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên thú cưng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: 'Mô tả',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _ageController,
                          labelText: 'Tuổi (tháng)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final age = int.tryParse(value.trim());
                              if (age == null || age < 0) {
                                return 'Tuổi phải là số dương';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _breedController,
                          labelText: 'Giống',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _getValidSpeciesValue(),
                          decoration: const InputDecoration(
                            labelText: 'Loài',
                            border: OutlineInputBorder(),
                          ),
                          items: _loadingSpecies
                              ? [const DropdownMenuItem(value: '', child: Text('Đang tải...'))]
                              : _speciesList.map((species) => DropdownMenuItem(
                                    value: species.name,
                                    child: Text(species.name),
                                  )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSpecies = value ?? '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _getValidGenderValue(),
                          decoration: const InputDecoration(
                            labelText: 'Giới tính',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Đực', child: Text('Đực')),
                            DropdownMenuItem(value: 'Cái', child: Text('Cái')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sale Information
              _buildSectionCard(
                'Thông tin bán',
                [
                  SwitchListTile(
                    title: const Text('Cho phép bán'),
                    subtitle: const Text('Thú cưng có thể được bán'),
                    value: _isForSale,
                    onChanged: (value) {
                      setState(() {
                        _isForSale = value;
                        if (!value) {
                          _priceController.clear();
                        }
                      });
                    },
                  ),
                  if (_isForSale) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _priceController,
                      labelText: 'Giá bán (VNĐ) *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_isForSale) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập giá bán';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null || price <= 0) {
                            return 'Giá bán phải là số dương';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Boarding Information
              _buildSectionCard(
                'Thông tin giữ dùm',
                [
                  SwitchListTile(
                    title: const Text('Cho phép giữ dùm'),
                    subtitle: const Text('Thú cưng có thể được giữ dùm'),
                    value: _isForBoarding,
                    onChanged: (value) {
                      setState(() {
                        _isForBoarding = value;
                        if (!value) {
                          _boardingPriceController.clear();
                          _specialInstructionsController.clear();
                        }
                      });
                    },
                  ),
                  if (_isForBoarding) ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _boardingPriceController,
                      labelText: 'Giá giữ dùm/ngày (VNĐ) *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_isForBoarding) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập giá giữ dùm';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null || price <= 0) {
                            return 'Giá giữ dùm phải là số dương';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _specialInstructionsController,
                      labelText: 'Mô tả giữ dùm',
                      maxLines: 3,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          'Lưu thay đổi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
