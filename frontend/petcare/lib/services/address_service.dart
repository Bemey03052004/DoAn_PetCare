import 'dart:convert';
import 'package:http/http.dart' as http;

class Province {
  final String code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'].toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

class District {
  final String code;
  final String name;

  District({required this.code, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      code: json['code'].toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

class Ward {
  final String code;
  final String name;

  Ward({required this.code, required this.name});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'].toString(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

class AddressService {
  static const String _apiBaseUrl = "https://provinces.open-api.vn/api";

  // Lấy danh sách tỉnh/thành
  static Future<List<Province>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/p/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching provinces: $error");
      return [];
    }
  }

  // Lấy danh sách quận/huyện theo tỉnh
  static Future<List<District>> getDistricts(String provinceCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/p/${Uri.encodeComponent(provinceCode)}?depth=2'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> districtsData = data['districts'] ?? [];
        return districtsData.map((json) => District.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching districts: $error");
      return [];
    }
  }

  // Lấy danh sách phường/xã theo quận/huyện
  static Future<List<Ward>> getWards(String districtCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/d/${Uri.encodeComponent(districtCode)}?depth=2'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> wardsData = data['wards'] ?? [];
        return wardsData.map((json) => Ward.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wards: ${response.statusCode}');
      }
    } catch (error) {
      print("Error fetching wards: $error");
      return [];
    }
  }

  // Tìm mã tỉnh theo tên
  static Future<String?> findProvinceCode(String provinceName) async {
    try {
      final provinces = await getProvinces();
      final province = provinces.firstWhere(
        (p) => p.name == provinceName,
        orElse: () => Province(code: '', name: ''),
      );
      return province.code.isNotEmpty ? province.code : null;
    } catch (error) {
      print("Error finding province code: $error");
      return null;
    }
  }

  // Tìm mã quận/huyện theo tên và mã tỉnh
  static Future<String?> findDistrictCode(String provinceCode, String districtName) async {
    try {
      final districts = await getDistricts(provinceCode);
      final district = districts.firstWhere(
        (d) => d.name == districtName,
        orElse: () => District(code: '', name: ''),
      );
      return district.code.isNotEmpty ? district.code : null;
    } catch (error) {
      print("Error finding district code: $error");
      return null;
    }
  }
}
