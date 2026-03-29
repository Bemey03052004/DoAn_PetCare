import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Kiểm tra permission và lấy vị trí hiện tại
  /// Trả về Position hoặc null nếu từ chối/không lấy được
  static Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // kiểm tra service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // không bật GPS -> thông báo cho user
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // quyền bị từ chối
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // quyền bị chặn vĩnh viễn, yêu cầu user bật trong settings
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      return pos;
    } catch (_) {
      return null;
    }
  }
}
