import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider_app/providers/auth_provider.dart';
import 'package:provider_app/screens/appointment.dart';
import 'package:provider_app/screens/business_image_screen.dart';
import 'package:provider_app/screens/home_screen.dart';
import 'package:provider_app/screens/settings.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_account.dart';
import 'screens/reset_password_screen.dart'; // Import the reset password screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NsaanoBusinessApp());
}

class NsaanoBusinessApp extends StatelessWidget {
  const NsaanoBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider()..loadLoginState(),
              lazy: false,
            ),
          ],
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Nsaano Business',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  useMaterial3: true,
                  brightness: Brightness.light,
                ),
                initialRoute: '/splash',
                routes: {
                  '/splash': (context) => const SplashScreen(),
                  '/create-account': (context) => const CreateAccountPage(),
                  '/login': (context) => const LoginScreen(),
                  '/reset-password': (context) => const ResetPasswordScreen(), // Add reset password route
                  '/home': (context) => const HomeScreen(),
                  '/gallery': (context) => const BusinessImagesScreen(),
                  '/appointments': (context) => const AppointmentScreen(),
                  '/settings': (context) => const SettingsScreen(),
                },
                onGenerateRoute: (settings) {
                  // No need to use Provider.of here since we're in the builder
                  if (settings.name == '/splash') {
                    return MaterialPageRoute(
                      builder: (context) => const SplashScreen(),
                    );
                  }
                  
                  // Protect routes that require authentication
                  if (['/home', '/gallery', '/appointments', '/settings'].contains(settings.name)) {
                    if (!authProvider.isLoggedIn) {
                      return MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      );
                    }
                  }
                  
                  return null;
                },
              );
            },
          ),
        );
      },
    );
  }
}