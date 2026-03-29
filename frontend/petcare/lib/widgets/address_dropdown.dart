import 'package:flutter/material.dart';
import '../services/address_service.dart';

class AddressDropdown extends StatefulWidget {
  final String? selectedProvince;
  final String? selectedDistrict;
  final String? selectedWard;
  final Function(String?, String?) onProvinceChanged; // (code, name)
  final Function(String?, String?) onDistrictChanged; // (code, name)
  final Function(String?, String?) onWardChanged; // (code, name)
  final String? provinceError;
  final String? districtError;
  final String? wardError;

  const AddressDropdown({
    super.key,
    this.selectedProvince,
    this.selectedDistrict,
    this.selectedWard,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onWardChanged,
    this.provinceError,
    this.districtError,
    this.wardError,
  });

  @override
  State<AddressDropdown> createState() => _AddressDropdownState();
}

class _AddressDropdownState extends State<AddressDropdown> {
  List<Province> _provinces = [];
  List<District> _districts = [];
  List<Ward> _wards = [];
  
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  // Store names for selected items
  String? _selectedProvinceName;
  String? _selectedDistrictName;
  String? _selectedWardName;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void didUpdateWidget(AddressDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Nếu tỉnh thay đổi, load lại quận/huyện
    if (oldWidget.selectedProvince != widget.selectedProvince) {
      if (widget.selectedProvince != null) {
        _loadDistricts(widget.selectedProvince!);
      } else {
        setState(() {
          _districts = [];
          _wards = [];
        });
        widget.onDistrictChanged(null, null);
        widget.onWardChanged(null, null);
      }
    }
    
    // Nếu quận/huyện thay đổi, load lại phường/xã
    if (oldWidget.selectedDistrict != widget.selectedDistrict) {
      if (widget.selectedDistrict != null) {
        _loadWards(widget.selectedDistrict!);
      } else {
        setState(() {
          _wards = [];
        });
        widget.onWardChanged(null, null);
      }
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });

    try {
      final provinces = await AddressService.getProvinces();
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      print('Error loading provinces: $e');
    } finally {
      setState(() {
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
    });

    try {
      final districts = await AddressService.getDistricts(provinceCode);
      setState(() {
        _districts = districts;
      });
    } catch (e) {
      print('Error loading districts: $e');
    } finally {
      setState(() {
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _loadWards(String districtCode) async {
    setState(() {
      _isLoadingWards = true;
    });

    try {
      final wards = await AddressService.getWards(districtCode);
      setState(() {
        _wards = wards;
      });
    } catch (e) {
      print('Error loading wards: $e');
    } finally {
      setState(() {
        _isLoadingWards = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tỉnh/Thành phố
        _buildDropdown(
          label: 'Tỉnh/Thành phố',
          value: widget.selectedProvince,
          items: _provinces.map((p) => DropdownMenuItem<String>(
            value: p.code,
            child: Text(p.name),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              final province = _provinces.firstWhere(
                (p) => p.code == value,
                orElse: () => Province(code: '', name: ''),
              );
              widget.onProvinceChanged(value, province.name.isNotEmpty ? province.name : null);
            } else {
              widget.onProvinceChanged(null, null);
            }
          },
          isLoading: _isLoadingProvinces,
          error: widget.provinceError,
        ),
        const SizedBox(height: 16),

        // Quận/Huyện
        _buildDropdown(
          label: 'Quận/Huyện',
          value: widget.selectedDistrict,
          items: _districts.map((d) => DropdownMenuItem<String>(
            value: d.code,
            child: Text(d.name),
          )).toList(),
          onChanged: (value) {
            if (widget.selectedProvince != null) {
              if (value != null) {
                final district = _districts.firstWhere(
                  (d) => d.code == value,
                  orElse: () => District(code: '', name: ''),
                );
                widget.onDistrictChanged(value, district.name.isNotEmpty ? district.name : null);
              } else {
                widget.onDistrictChanged(null, null);
              }
            }
          },
          isLoading: _isLoadingDistricts,
          error: widget.districtError,
          enabled: widget.selectedProvince != null,
        ),
        const SizedBox(height: 16),

        // Phường/Xã
        _buildDropdown(
          label: 'Phường/Xã',
          value: widget.selectedWard,
          items: _wards.map((w) => DropdownMenuItem<String>(
            value: w.code,
            child: Text(w.name),
          )).toList(),
          onChanged: (value) {
            if (widget.selectedDistrict != null) {
              if (value != null) {
                final ward = _wards.firstWhere(
                  (w) => w.code == value,
                  orElse: () => Ward(code: '', name: ''),
                );
                widget.onWardChanged(value, ward.name.isNotEmpty ? ward.name : null);
              } else {
                widget.onWardChanged(null, null);
              }
            }
          },
          isLoading: _isLoadingWards,
          error: widget.wardError,
          enabled: widget.selectedDistrict != null,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required bool isLoading,
    String? error,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null 
                ? Colors.red.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            color: enabled ? Colors.white : Colors.grey[100],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText: isLoading 
                ? 'Đang tải...' 
                : 'Chọn $label',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
            style: TextStyle(
              color: enabled ? Colors.black87 : Colors.grey[500],
              fontSize: 16,
            ),
            icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
            dropdownColor: Colors.white,
            isExpanded: true,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
