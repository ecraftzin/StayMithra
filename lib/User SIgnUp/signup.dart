import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:staymitra/User%20Login/login.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double fontSize = MediaQuery.of(context).size.width < 600 ? 22 : 26;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 71, 88, 141),
                  Color.fromARGB(255, 0, 60, 150)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative Icons (Matching login)
          Positioned(
            top: 50,
            left: 30,
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.cloud, size: 80, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 50,
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.waves, size: 100, color: Colors.white),
            ),
          ),

          // SignUp Form
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Create Account",
                        style: GoogleFonts.montserrat(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      buildInputField("First Name", Icons.person_outline),
                      const SizedBox(height: 15),

                      buildInputField("Last Name", Icons.person),
                      const SizedBox(height: 15),

                      buildInputField("Email", Icons.email_outlined),
                      const SizedBox(height: 15),

                      buildInputField("Phone Number", Icons.phone_outlined),
                      const SizedBox(height: 15),

                      buildInputField("Place", Icons.location_on_outlined),
                      const SizedBox(height: 15),

                      buildInputField("Password", Icons.lock_outline, obscure: true),
                      const SizedBox(height: 15),

                      buildInputField("Confirm Password", Icons.lock, obscure: true),
                      const SizedBox(height: 25),

                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Get Started"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Login",
                                style: GoogleFonts.poppins(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(String label, IconData icon, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
