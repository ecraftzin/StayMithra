import 'package:flutter/material.dart';
import 'package:staymitra/UserLogin/login.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    // Background
                    SizedBox(
                      width: width,
                      height: height,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/signinup.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    // Foreground
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header: logo on top-left (replaces texts)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.06,
                            vertical: height * 0.03,
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo/staymithra_logo.png', // <- your logo
                              height: height * 0.06,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(height: height * 0.02),

                        // Card
                        Container(
                          width: width * 0.9,
                          padding: EdgeInsets.all(width * 0.06),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(width * 0.06),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Let’s ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D5948),
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Travel you in.",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF007F8C),
                                        fontSize: width * 0.06,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                "Discover the World with Every Sign Up",
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: const Color(0xFF2D5948),
                                ),
                              ),
                              SizedBox(height: height * 0.03),

                              _buildInputField("Username", width),
                              SizedBox(height: height * 0.02),
                              _buildInputField("Email/Phone Number", width),
                              SizedBox(height: height * 0.02),
                              _buildInputField("Place", width),
                              SizedBox(height: height * 0.02),
                              _buildInputField("Password", width, isPassword: true),

                              SizedBox(height: height * 0.02),

                              // Sign Up
                              SizedBox(
                                width: double.infinity,
                                height: height * 0.065,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007F8C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(width * 0.07),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignInPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.045,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: height * 0.025),

                              Center(
                                child: Text(
                                  "or sign in with",
                                  style: TextStyle(fontSize: width * 0.04),
                                ),
                              ),
                              SizedBox(height: height * 0.02),

                              // Social
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final asset in const [
                                    'google.png',
                                    'apple.png',
                                    'facebook.png',
                                  ])
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                                      child: Container(
                                        padding: EdgeInsets.all(width * 0.025),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(width * 0.03),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/Signinwith/$asset',
                                          width: width * 0.08,
                                          height: width * 0.08,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.02),

                        // Bottom "Sign In" button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                          child: SizedBox(
                            width: double.infinity,
                            height: height * 0.06,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF007F8C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(width * 0.07),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignInPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Sign In",
                                style: TextStyle(fontSize: width * 0.045),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Keep helpers INSIDE the class
  Widget _buildInputField(String hint, double width, {bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword,
      style: TextStyle(fontSize: width * 0.04),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: width * 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.035),
        ),
      ),
    );
  }
}
