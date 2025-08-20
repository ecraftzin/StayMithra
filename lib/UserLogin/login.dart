import 'package:flutter/material.dart';
import 'package:staymitra/ForgotPassword/forgotpassword.dart';
import 'package:staymitra/UserSIgnUp/signup.dart';
import 'package:staymitra/services/auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (response['success'] == true) {
          // Login successful and email verified
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          // Login failed or email not verified
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    response['needsVerification'] == true
                        ? Icons.warning
                        : Icons.error,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      response['message'] ?? 'Login failed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: response['needsVerification'] == true
                  ? Colors.orange
                  : Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // If email needs verification, show resend option
          if (response['needsVerification'] == true) {
            _showResendVerificationDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final response = await _authService.signInWithGoogle();

      if (mounted) {
        if (response['success'] == true) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          String errorMessage = response['message'] ?? 'Google sign-in failed';
          Color backgroundColor = Colors.red;

          // Check for specific error types
          if (errorMessage.contains('provider is not enabled') ||
              errorMessage.contains('redirect_uri_mismatch') ||
              errorMessage.contains('invalid request')) {
            errorMessage =
                'Google sign-in is not configured yet. Please use email signup for now.';
            backgroundColor = Colors.orange;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    backgroundColor == Colors.orange
                        ? Icons.warning
                        : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    try {
      final success = await _authService.signInWithApple();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Apple sign in failed';
        if (e.toString().contains('provider is not enabled')) {
          errorMessage =
              'Apple sign-in is not configured yet. Please use email signup for now.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final success = await _authService.signInWithFacebook();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Facebook sign in failed';
        if (e.toString().contains('provider is not enabled')) {
          errorMessage =
              'Facebook sign-in is not configured yet. Please use email signup for now.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showResendVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'Your email address needs to be verified before you can log in. Would you like us to resend the verification email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resendVerificationEmail();
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final response = await _authService.resendEmailVerification(
        _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Email sent'),
            backgroundColor:
                response['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Background image
                      Container(
                        width: width,
                        height: height,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/signinup.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.06,
                              vertical: height * 0.03,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/logo/staymithra_logo.png', // change to your logo path
                                height: height * 0.06, // adjust size
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.02),

                          // Main Container
                          Form(
                            key: _formKey,
                            child: Container(
                              width: width * 0.9,
                              padding: EdgeInsets.all(width * 0.06),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(width * 0.06),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Heading
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
                                    "Discover the World with Every Sign In",
                                    style: TextStyle(
                                      fontSize: width * 0.04,
                                      color: const Color(0xFF2D5948),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.03),

                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(fontSize: width * 0.04),
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle:
                                          TextStyle(fontSize: width * 0.04),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            width * 0.035),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: height * 0.02),

                                  // Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(fontSize: width * 0.04),
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle:
                                          TextStyle(fontSize: width * 0.04),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            width * 0.035),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: height * 0.015),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordPage()));
                                      },
                                      child: Text(
                                        "Forgot password?",
                                        style:
                                            TextStyle(fontSize: width * 0.04),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: height * 0.01),

                                  // Sign In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: height * 0.065,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF007F8C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              width * 0.07),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _signIn,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : Text("Sign In",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: width * 0.045)),
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

                                  // Social Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Sign In
                                      GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : _signInWithGoogle,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02),
                                          child: Container(
                                            padding:
                                                EdgeInsets.all(width * 0.025),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      width * 0.03),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/Signinwith/google.png',
                                              width: width * 0.08,
                                              height: width * 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Apple Sign In
                                      GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : _signInWithApple,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02),
                                          child: Container(
                                            padding:
                                                EdgeInsets.all(width * 0.025),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      width * 0.03),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/Signinwith/apple.png',
                                              width: width * 0.08,
                                              height: width * 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Facebook Sign In
                                      GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : _signInWithFacebook,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02),
                                          child: Container(
                                            padding:
                                                EdgeInsets.all(width * 0.025),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      width * 0.03),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              'assets/Signinwith/facebook.png',
                                              width: width * 0.08,
                                              height: width * 0.08,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: height * 0.02),

                                  Center(
                                    child: Text(
                                      "I don’t have an account?",
                                      style: TextStyle(fontSize: width * 0.04),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.025),

                          // Sign Up Button
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: width * 0.06),
                            child: SizedBox(
                              width: double.infinity,
                              height: height * 0.06,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF007F8C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(width * 0.07),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupPage(),
                                    ),
                                  );
                                },
                                child: Text("Sign Up",
                                    style: TextStyle(fontSize: width * 0.045)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
