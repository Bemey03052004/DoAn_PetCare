import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _biometricEmailKey = 'biometric_email';
  static const _biometricPasswordKey = 'biometric_password';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Kiểm tra xem thiết bị có hỗ trợ biometric không
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra xem có biometric nào được đăng ký không
  Future<bool> hasEnrolledBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách các loại biometric có sẵn
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Kiểm tra xem biometric có được bật không
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Bật/tắt biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
    } catch (e) {
      throw Exception('Không thể lưu cài đặt biometric: $e');
    }
  }

  /// Lưu thông tin đăng nhập cho biometric
  Future<void> saveBiometricCredentials(String email, String password) async {
    try {
      await _storage.write(key: _biometricEmailKey, value: email);
      await _storage.write(key: _biometricPasswordKey, value: password);
    } catch (e) {
      throw Exception('Không thể lưu thông tin đăng nhập: $e');
    }
  }

  /// Lấy thông tin đăng nhập đã lưu
  Future<Map<String, String?>> getBiometricCredentials() async {
    try {
      final email = await _storage.read(key: _biometricEmailKey);
      final password = await _storage.read(key: _biometricPasswordKey);
      return {'email': email, 'password': password};
    } catch (e) {
      return {'email': null, 'password': null};
    }
  }

  /// Xóa thông tin đăng nhập biometric
  Future<void> clearBiometricCredentials() async {
    try {
      await _storage.delete(key: _biometricEmailKey);
      await _storage.delete(key: _biometricPasswordKey);
    } catch (e) {
      throw Exception('Không thể xóa thông tin đăng nhập: $e');
    }
  }

  /// Thực hiện xác thực biometric
  Future<bool> authenticateWithBiometric({
    String reason = 'Xác thực danh tính của bạn',
    String cancelButton = 'Hủy',
    String goToSettingsButton = 'Cài đặt',
    String goToSettingsDescription = 'Vui lòng cài đặt xác thực sinh trắc học',
  }) async {
    try {
      // Kiểm tra thiết bị có hỗ trợ không
      if (!await isDeviceSupported()) {
        throw Exception('Thiết bị không hỗ trợ xác thực sinh trắc học');
      }

      // Kiểm tra có biometric nào được đăng ký không
      if (!await hasEnrolledBiometrics()) {
        throw Exception('Chưa có xác thực sinh trắc học nào được đăng ký');
      }

        // Thực hiện xác thực
        final result = await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            sensitiveTransaction: true,
          ),
        );

      return result;
    } catch (e) {
      throw Exception('Lỗi xác thực sinh trắc học: $e');
    }
  }

  /// Lấy tên loại biometric
  String getBiometricTypeName(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID / Vân tay';
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Xác thực sinh trắc học';
    }
  }

  /// Kiểm tra xem có thể sử dụng biometric không
  Future<bool> canUseBiometric() async {
    try {
      final isSupported = await isDeviceSupported();
      final hasEnrolled = await hasEnrolledBiometrics();
      final isEnabled = await isBiometricEnabled();
      
      return isSupported && hasEnrolled && isEnabled;
    } catch (e) {
      return false;
    }
  }
}
