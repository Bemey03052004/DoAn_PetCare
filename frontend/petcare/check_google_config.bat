@echo off
echo Checking Google Sign-In configuration...
echo.

echo 1. Checking google-services.json...
if exist "android\app\google-services.json" (
    echo ✅ google-services.json exists
    findstr "petcare-dc7bc" android\app\google-services.json >nul
    if %errorlevel% equ 0 (
        echo ✅ Project ID is correct: petcare-dc7bc
    ) else (
        echo ❌ Project ID is incorrect
    )
    
    findstr "com.petcare.petcare" android\app\google-services.json >nul
    if %errorlevel% equ 0 (
        echo ✅ Package name is correct: com.petcare.petcare
    ) else (
        echo ❌ Package name is incorrect
    )
    
    findstr "893b1de8ae1186b4875badd7456acb6423a3695b" android\app\google-services.json >nul
    if %errorlevel% equ 0 (
        echo ✅ SHA-1 fingerprint is correct
    ) else (
        echo ❌ SHA-1 fingerprint is incorrect
    )
) else (
    echo ❌ google-services.json not found
)

echo.
echo 2. Checking Android configuration...
findstr "google-services" android\app\build.gradle >nul
if %errorlevel% equ 0 (
    echo ✅ Google Services plugin is configured
) else (
    echo ❌ Google Services plugin is missing
)

findstr "play-services-auth" android\app\build.gradle >nul
if %errorlevel% equ 0 (
    echo ✅ Google Play Services Auth dependency is configured
) else (
    echo ❌ Google Play Services Auth dependency is missing
)

echo.
echo 3. Checking Flutter configuration...
findstr "serverClientId" lib\services\google_auth_service.dart >nul
if %errorlevel% equ 0 (
    echo ✅ Server Client ID is configured
) else (
    echo ❌ Server Client ID is missing
)

echo.
echo 4. Current SHA-1 fingerprint:
keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android | findstr "SHA1"

echo.
echo Configuration check completed!
pause
