import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';

class BiometricProvider with ChangeNotifier {
  final BiometricService _biometricService = BiometricService();

  bool _isBiometricEnabled = false;
  bool _isLoading = false;
  String _biometricTypeName = 'Xác thực sinh trắc học';
  bool _canUseBiometric = false;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isLoading => _isLoading;
  String get biometricTypeName => _biometricTypeName;
  bool get canUseBiometric => _canUseBiometric;

  BiometricProvider() {
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    _setLoading(true);
    try {
      // Kiểm tra xem biometric có được bật không
      _isBiometricEnabled = await _biometricService.isBiometricEnabled();
      
      // Kiểm tra xem có thể sử dụng biometric không
      _canUseBiometric = await _biometricService.canUseBiometric();
      
      // Lấy tên loại biometric
      if (_canUseBiometric) {
        final availableBiometrics = await _biometricService.getAvailableBiometrics();
        _biometricTypeName = _biometricService.getBiometricTypeName(availableBiometrics);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo biometric: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Bật/tắt biometric
  Future<bool> toggleBiometric() async {
    _setLoading(true);
    try {
      final newValue = !_isBiometricEnabled;
      await _biometricService.setBiometricEnabled(newValue);
      _isBiometricEnabled = newValue;
      
      // Cập nhật trạng thái có thể sử dụng
      _canUseBiometric = await _biometricService.canUseBiometric();
      
      return true;
    } catch (e) {
      debugPrint('Lỗi toggle biometric: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Lưu thông tin đăng nhập cho biometric
  Future<bool> saveBiometricCredentials(String email, String password) async {
    try {
      await _biometricService.saveBiometricCredentials(email, password);
      return true;
    } catch (e) {
      debugPrint('Lỗi lưu thông tin đăng nhập: $e');
      return false;
    }
  }

  /// Lấy thông tin đăng nhập đã lưu
  Future<Map<String, String?>> getBiometricCredentials() async {
    try {
      return await _biometricService.getBiometricCredentials();
    } catch (e) {
      debugPrint('Lỗi lấy thông tin đăng nhập: $e');
      return {'email': null, 'password': null};
    }
  }

  /// Xóa thông tin đăng nhập biometric
  Future<bool> clearBiometricCredentials() async {
    try {
      await _biometricService.clearBiometricCredentials();
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa thông tin đăng nhập: $e');
      return false;
    }
  }

  /// Thực hiện xác thực biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      return await _biometricService.authenticateWithBiometric();
    } catch (e) {
      debugPrint('Lỗi xác thực biometric: $e');
      return false;
    }
  }

  /// Kiểm tra và cập nhật trạng thái biometric
  Future<void> refreshBiometricStatus() async {
    await _initializeBiometric();
  }

  /// Kiểm tra xem có thể sử dụng biometric không
  Future<bool> checkCanUseBiometric() async {
    try {
      _canUseBiometric = await _biometricService.canUseBiometric();
      notifyListeners();
      return _canUseBiometric;
    } catch (e) {
      debugPrint('Lỗi kiểm tra biometric: $e');
      return false;
    }
  }
}
