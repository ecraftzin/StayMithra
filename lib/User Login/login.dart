import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:staymitra/Home/home.dart';
import 'package:staymitra/User%20SIgnUp/signup.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double fontSize = MediaQuery.of(context).size.width < 600 ? 20 : 24;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 71, 88, 141), Color.fromARGB(255, 0, 60, 150)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative Abstract Icons
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

          // Responsive Login Form
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: Center(
                child:Padding(padding:const EdgeInsets.symmetric(vertical: 40, horizontal: 20), 
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width;

                    if (constraints.maxWidth < 600) {
                      width = constraints.maxWidth * 0.9; // Mobile
                    } else if (constraints.maxWidth < 1024) {
                      width = constraints.maxWidth * 0.6; // Tablet
                    } else {
                      width = 400; // Desktop
                    }

                    return Container(
                      width: width,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email Input
                          TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          TextField(
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white38),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign In Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context,MaterialPageRoute(builder: (context)=>HomePage()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Sign In"),
                          ),
                          const SizedBox(height: 20),

                          // Social Login Text
                          const Text(
                            "or login with",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 15),

                          // Social Buttons
                          Column(
                            children: [
                              SignInButton(
                                Buttons.google,
                                onPressed: () {},             
                              ),
                              const SizedBox(height: 10),
                              SignInButton(
                                Buttons.apple,
                                onPressed: () {},
                              ),
                              TextButton(onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
                              }, 
                              child: RichText(text: TextSpan(
                                text: "Create an Account?",
                                children: <TextSpan>[
                                TextSpan(text: "Sign Up",
                                style: TextStyle(color: Colors.cyanAccent,fontSize: 20))
                                ]
                              )))
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          )
        ],
      ),
    );
  }
}
