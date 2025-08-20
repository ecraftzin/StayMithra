import 'package:flutter/material.dart';
import 'package:staymitra/UserLogin/login.dart';

class EmailVerifiedPage extends StatelessWidget {
  const EmailVerifiedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation/icon
              Container(
                width: width * 0.35,
                height: width * 0.35,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: width * 0.2,
                  color: Colors.green,
                ),
              ),
              
              SizedBox(height: height * 0.04),
              
              // Success title
              Text(
                'Email Verified Successfully!',
                style: TextStyle(
                  fontSize: width * 0.065,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: height * 0.02),
              
              // Success message
              Text(
                'Your email has been verified successfully. You can now log in to your account and start using StayMithra.',
                style: TextStyle(
                  fontSize: width * 0.04,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: height * 0.05),
              
              // Success info box
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(width * 0.03),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: width * 0.05,
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        'Your account is now active and ready to use. Welcome to StayMithra!',
                        style: TextStyle(
                          fontSize: width * 0.035,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: height * 0.05),
              
              // Login button
              SizedBox(
                width: double.infinity,
                height: height * 0.06,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007F8C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                  ),
                  child: Text(
                    'Continue to Login',
                    style: TextStyle(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: height * 0.03),
              
              // Additional info
              Text(
                'You can now close this page and return to the app to log in.',
                style: TextStyle(
                  fontSize: width * 0.032,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
