import 'package:flutter/material.dart';
import 'package:staymitra/MainPage/mainpage.dart';
import 'package:staymitra/SplashScreen/getstarted.dart';
import 'package:staymitra/SplashScreen/splashscreen.dart';
import 'package:staymitra/UserLogin/login.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        '/': (context) => const SplashScreen(),
        '/get-started': (context) => const GetStartedPage(),
        '/signin': (context) => const SignInPage(),
         '/main': (context) => const MainPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

