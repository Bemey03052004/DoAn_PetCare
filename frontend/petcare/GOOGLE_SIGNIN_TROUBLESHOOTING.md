# Hướng dẫn khắc phục lỗi Google Sign-In

## Tình trạng hiện tại
- ✅ File `google-services.json` đã được cấu hình đúng
- ✅ SHA-1 fingerprint đã khớp: `89:3B:1D:E8:AE:11:86:B4:87:5B:AD:D7:45:6A:CB:64:23:A3:69:5B`
- ✅ Android configuration đã được cập nhật
- ✅ Server Client ID đã được thêm vào code

## Các bước đã thực hiện

### 1. Cập nhật Android Configuration
- ✅ Thêm Google Services plugin vào `android/app/build.gradle`
- ✅ Thêm Google Services classpath vào `android/build.gradle`
- ✅ Thêm Google Play Services dependency
- ✅ Thêm meta-data vào `AndroidManifest.xml`

### 2. Cập nhật Flutter Code
- ✅ Thêm server client ID vào `GoogleSignIn` configuration
- ✅ Cải thiện error handling

## Cách test Google Sign-In

### Bước 1: Chạy ứng dụng
```bash
cd petcare
flutter clean
flutter pub get
flutter run
```

### Bước 2: Test Google Sign-In
1. Mở ứng dụng
2. Vào màn hình Login
3. Click nút "Đăng nhập với Google"
4. Kiểm tra kết quả

## Nếu vẫn còn lỗi

### Kiểm tra Google Cloud Console
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Chọn project `petcare-dc7bc`
3. Vào **APIs & Services** > **Credentials**
4. Kiểm tra OAuth 2.0 Client ID:
   - Package name: `com.petcare.petcare`
   - SHA-1: `89:3B:1D:E8:AE:11:86:B4:87:5B:AD:D7:45:6A:CB:64:23:A3:69:5B`

### Kiểm tra file google-services.json
Đảm bảo file `petcare/android/app/google-services.json` có:
- Project ID: `petcare-dc7bc`
- Package name: `com.petcare.petcare`
- SHA-1 fingerprint: `893b1de8ae1186b4875badd7456acb6423a3695b`

### Kiểm tra Android Studio
1. Mở project trong Android Studio
2. Sync project với Gradle files
3. Kiểm tra có lỗi nào không

## Debug Commands

### Lấy SHA-1 fingerprint mới
```bash
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android
```

### Kiểm tra Google Services
```bash
# Trong Android Studio
./gradlew app:dependencies
```

### Clean và rebuild
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## Lưu ý quan trọng
- Đảm bảo Google Sign-In API đã được kích hoạt trong Google Cloud Console
- Kiểm tra billing account nếu cần
- Đảm bảo OAuth consent screen đã được cấu hình

## Nếu vẫn không hoạt động
Có thể cần:
1. Tạo OAuth client ID mới
2. Kiểm tra lại SHA-1 fingerprint
3. Đảm bảo package name chính xác
4. Kiểm tra Google Play Services trên thiết bị
