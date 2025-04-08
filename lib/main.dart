import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider_app/providers/auth_provider.dart';
import 'package:provider_app/screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_account.dart';  // Create Account Screen

void main() {
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
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nsaano Business',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.dark,  // Dark Mode Theme
            ),
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/create-account': (context) => const CreateAccountPage(),  // Account creation page
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          ),
        );
      },
    );
  }
}
