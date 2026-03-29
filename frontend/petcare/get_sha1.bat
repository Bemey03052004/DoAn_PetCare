@echo off
echo Getting SHA-1 fingerprint for Google Sign-In setup...
echo.

REM Try to find Java keytool
set KEYTOOL_PATH=
where keytool >nul 2>&1
if %errorlevel% equ 0 (
    set KEYTOOL_PATH=keytool
) else (
    REM Try common Java installation paths
    if exist "C:\Program Files\Java\jdk*\bin\keytool.exe" (
        for /d %%i in ("C:\Program Files\Java\jdk*") do set KEYTOOL_PATH=%%i\bin\keytool.exe
    )
    if exist "C:\Program Files (x86)\Java\jdk*\bin\keytool.exe" (
        for /d %%i in ("C:\Program Files (x86)\Java\jdk*") do set KEYTOOL_PATH=%%i\bin\keytool.exe
    )
    if exist "%JAVA_HOME%\bin\keytool.exe" (
        set KEYTOOL_PATH=%JAVA_HOME%\bin\keytool.exe
    )
)

if "%KEYTOOL_PATH%"=="" (
    echo ERROR: Java keytool not found!
    echo Please install Java JDK or add it to your PATH
    echo.
    echo Alternative: Use Android Studio
    echo 1. Open Android Studio
    echo 2. Open your project
    echo 3. Click on Gradle tab (right side)
    echo 4. Navigate to: app > Tasks > android > signingReport
    echo 5. Double-click signingReport
    echo 6. Look for SHA1 in the output
    pause
    exit /b 1
)

echo Using keytool: %KEYTOOL_PATH%
echo.

REM Get SHA-1 fingerprint
echo Getting SHA-1 fingerprint from debug keystore...
%KEYTOOL_PATH% -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo Copy the SHA1 value above and use it in Google Cloud Console
echo.
pause
