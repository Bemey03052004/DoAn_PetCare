import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showBiometricPrompt = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final authProvider = context.read<AuthProvider>();
    final biometricProvider = context.read<BiometricProvider>();
    
    final isLoggedIn = await authProvider.tryAutoLogin();

    if (isLoggedIn) {
      // Kiểm tra xem có thể sử dụng biometric không
      final canUseBiometric = await biometricProvider.checkCanUseBiometric();
      
      if (canUseBiometric && biometricProvider.isBiometricEnabled) {
        // Hiển thị prompt biometric
        setState(() {
          _showBiometricPrompt = true;
        });
      } else {
        // Chuyển thẳng đến home
      Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final biometricProvider = context.read<BiometricProvider>();
    
    try {
      final authenticated = await biometricProvider.authenticateWithBiometric();
      if (authenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Nếu xác thực thất bại, chuyển về login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Nếu có lỗi, chuyển về login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skipBiometric() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_showBiometricPrompt) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  const Icon(
                    Icons.pets,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'PetCare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Chào mừng bạn quay trở lại!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Biometric Icon
                  Consumer<BiometricProvider>(
                    builder: (context, biometricProvider, child) {
                      return Icon(
                        biometricProvider.biometricTypeName.contains('Face') 
                          ? Icons.face 
                          : Icons.fingerprint,
                        size: 80,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Consumer<BiometricProvider>(
                    builder: (context, biometricProvider, child) {
                      return Text(
                        'Mở khóa bằng ${biometricProvider.biometricTypeName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Chạm vào biểu tượng để xác thực',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Biometric Button
                  Consumer<BiometricProvider>(
                    builder: (context, biometricProvider, child) {
                      return GestureDetector(
                        onTap: _authenticateWithBiometric,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            biometricProvider.biometricTypeName.contains('Face') 
                              ? Icons.face 
                              : Icons.fingerprint,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Skip Button
                  TextButton(
                    onPressed: _skipBiometric,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'PetCare',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
