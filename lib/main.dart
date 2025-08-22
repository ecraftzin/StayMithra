import 'package:flutter/material.dart';
import 'package:staymitra/MainPage/mainpage.dart';
import 'package:staymitra/SplashScreen/getstarted.dart';
import 'package:staymitra/UserLogin/login.dart';
import 'package:staymitra/UserSIgnUp/email_verified_page.dart';
import 'package:staymitra/config/supabase_config.dart';
import 'package:staymitra/auth/auth_wrapper.dart';
import 'package:staymitra/services/storage_service.dart';
import 'package:staymitra/Posts/create_post_page.dart';
import 'package:staymitra/Campaigns/create_campaign_page.dart';

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
      home: const AuthWrapper(),
      routes: {
        '/get-started': (context) => const GetStartedPage(),
        '/signin': (context) => const SignInPage(),
        '/login': (context) => const SignInPage(),
        '/main': (context) => const MainPage(),
        '/email-verified': (context) => const EmailVerifiedPage(),
        '/create-post': (context) => const CreatePostPage(),
        '/create-campaign': (context) => const CreateCampaignPage(),
      },
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        );
      },
    );
  }
}
