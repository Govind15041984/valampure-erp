import 'package:flutter/material.dart';
// Note: If you aren't using Riverpod yet for Valampure, you can remove ProviderScope
// import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_colors.dart';
import 'features/auth/screens/mobile_screen.dart';
import 'features/auth/screens/pin_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Wrap in ProviderScope only if you've added flutter_riverpod to pubspec.yaml
  runApp(const ValampureApp());
}

class ValampureApp extends StatelessWidget {
  const ValampureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valampure ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/pin') {
          // Extract the mobile number passed from MobileScreen
          final mobileNumber = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => PinScreen(mobileNumber: mobileNumber),
          );
        }
        if (settings.name == '/signup') {
          // Extract the mobile number passed from MobileScreen
          final mobile = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SignupScreen(mobile: mobile),
          );
        }
        return null; // Fallback to routes map
      },
      routes: {
        '/': (context) => const MobileScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
