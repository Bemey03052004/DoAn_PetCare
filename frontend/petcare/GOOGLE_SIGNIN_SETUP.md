# Hướng dẫn cấu hình Google Sign-In

## Lỗi hiện tại
```
PlatformException: channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.google_sign_in_android.GoogleSignInApi.init"
```

## Nguyên nhân
Lỗi này xảy ra vì Google Sign-In chưa được cấu hình đúng cách trên Android.

## Giải pháp

### Bước 1: Tạo Google Cloud Project
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện có
3. Kích hoạt Google Sign-In API

### Bước 2: Tạo OAuth 2.0 Client ID
1. Vào **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth 2.0 Client ID**
3. Chọn **Android** làm Application type
4. Nhập thông tin:
   - **Package name**: `com.petcare.petcare`
   - **SHA-1 certificate fingerprint**: Cần lấy từ debug keystore

### Bước 3: Lấy SHA-1 Fingerprint
Chạy lệnh sau trong terminal (cần có Java JDK):

**Windows:**
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**macOS/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Tìm dòng **SHA1** và copy giá trị.

### Bước 4: Tải google-services.json
1. Sau khi tạo OAuth client, tải file `google-services.json`
2. Thay thế file `petcare/android/app/google-services.json` hiện tại
3. Đảm bảo package name trong file khớp với `com.petcare.petcare`

### Bước 5: Cấu hình Android
File `android/app/build.gradle` đã được cập nhật với:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // Đã thêm
}
```

File `android/build.gradle` đã được cập nhật với:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'  // Đã thêm
    }
}
```

### Bước 6: Clean và Rebuild
```bash
cd petcare
flutter clean
flutter pub get
flutter run
```

## Lưu ý quan trọng
- File `google-services.json` hiện tại chỉ là mẫu, cần thay thế bằng file thật từ Google Console
- SHA-1 fingerprint phải chính xác
- Package name phải khớp với `com.petcare.petcare`

## Kiểm tra
Sau khi cấu hình xong, Google Sign-In sẽ hoạt động bình thường và không còn lỗi channel-error.
