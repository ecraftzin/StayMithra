import 'package:flutter/material.dart';
import 'package:staymitra/MainPage/mainpage.dart';
import 'package:staymitra/SplashScreen/getstarted.dart';
import 'package:staymitra/UserLogin/login.dart';
import 'package:staymitra/UserSIgnUp/email_verified_page.dart';
import 'package:staymitra/config/supabase_config.dart';
import 'package:staymitra/auth/auth_wrapper.dart';
import 'package:staymitra/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize storage buckets
  try {
    await StorageService().createBucketsIfNeeded();
  } catch (e) {
    print('Storage initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staymithra',
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/get-started': (context) => const GetStartedPage(),
        '/signin': (context) => const SignInPage(),
        '/login': (context) => const SignInPage(),
        '/main': (context) => const MainPage(),
        '/email-verified': (context) => const EmailVerifiedPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
