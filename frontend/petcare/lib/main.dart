import 'dart:io';
import 'package:flutter/material.dart';
import 'package:petcare/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/role_provider.dart';
import 'providers/biometric_provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/role_service.dart';
import 'services/pet_service.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_sessions_screen.dart';
import 'screens/admin/user_list_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_pets_screen.dart';
import 'screens/admin_transactions_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_boarding_screen.dart';
import 'screens/admin_adoption_screen.dart';
import 'screens/admin_species_screen.dart';
import 'providers/pet_provider.dart';
import 'screens/public_pets_screen.dart';
import 'screens/create_pet_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/chat_screen.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin_stats_screen.dart';
import 'screens/user_stats_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_reset_code_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/pet_adoption_requests_screen.dart';
import 'screens/boarding_status_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true; // ⚠️ Bỏ SSL check trong local test
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  
  // Create services
  final authService = AuthService();
  final userService = UserService(authService);
  final roleService = RoleService(authService);
  final petService = PetService(authService);
  final notificationService = NotificationService(authService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(userService),
          update: (_, auth, previous) => previous ?? UserProvider(userService),
        ),
        ChangeNotifierProvider(create: (_) => RoleProvider(roleService)),
        ChangeNotifierProvider(create: (_) => PetProvider(petService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(notificationService)),
        ChangeNotifierProvider(create: (_) => BiometricProvider()),
      ],
      child: const PetCareApp(),
    ),
  );
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegistrationScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/login-sessions': (_) => const LoginSessionsScreen(),
        '/admin/dashboard': (_) => const AdminDashboardScreen(),
        '/admin/pets': (_) => const AdminPetsScreen(),
        '/admin/transactions': (_) => const AdminTransactionsScreen(),
        '/admin/users': (_) => const AdminUsersScreen(),
        '/admin/boarding': (_) => const AdminBoardingScreen(),
        '/admin/adoption': (_) => const AdminAdoptionScreen(),
        '/admin/species': (_) => const AdminSpeciesScreen(),
        '/pets/public': (_) => const PublicPetsScreen(),
        '/pets/create': (_) => const CreatePetScreen(),
        '/pets/detail': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return PetDetailScreen(petId: id);
        },
        '/pets/adoptions': (ctx) {
          final petId = ModalRoute.of(ctx)!.settings.arguments as int;
          return PetAdoptionRequestsScreen(petId: petId);
        },
        '/boarding/status': (ctx) {
          final boardingRequestId = ModalRoute.of(ctx)!.settings.arguments as int;
          return BoardingStatusScreen(boardingRequestId: boardingRequestId);
        },
        '/chat': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments;
          if (args is int) {
            // Old way: arguments is int (otherUserId)
            return ChatScreen(otherUserId: args);
          } else if (args is Map<String, dynamic>) {
            // New way: arguments is Map with otherUserId, petName, chatType
            final otherUserId = args['otherUserId'] as int?;
            final roomId = args['roomId'] as String?;
            final title = args['title'] as String?;
            final petName = args['petName'] as String?;
            final chatType = args['chatType'] as String?;
            
            if (otherUserId != null) {
              return ChatScreen(
                otherUserId: otherUserId,
                petName: petName,
                chatType: chatType,
              );
            } else if (roomId != null && title != null) {
              return ChatScreen(
                roomId: roomId,
                title: title,
                petName: petName,
                chatType: chatType,
              );
            } else {
              throw ArgumentError('Invalid arguments for /chat route');
            }
          } else {
            throw ArgumentError('Invalid arguments for /chat route');
          }
        },
        '/notifications': (_) => const NotificationsScreen(),
        '/stats/admin': (_) => const AdminStatsScreen(),
        '/stats/me': (_) => const UserStatsScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/verify-reset-code': (ctx) {
          final email = ModalRoute.of(ctx)!.settings.arguments as String;
          return VerifyResetCodeScreen(email: email);
        },
        '/reset-password': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, String>;
          return ResetPasswordScreen(
            email: args['email']!,
            code: args['code']!,
          );
        },
        '/verify-email': (ctx) {
          final email = ModalRoute.of(ctx)!.settings.arguments as String;
          return VerifyEmailScreen(email: email);
        },
      },
    );
  }
}
