// import 'package:flutter/material.dart';

// class ForgotPassword extends StatelessWidget {
//   const ForgotPassword({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     return Scaffold(
//       backgroundColor: const Color(0xFF007F8C),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top Header
//             Padding(
//               padding: EdgeInsets.symmetric(
//                   horizontal: width * 0.06, vertical: height * 0.03),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     "staymithra",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 26,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Row(
//                     children: const [
//                       Text(
//                         "English",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Icon(Icons.keyboard_arrow_down, color: Colors.white),
//                     ],
//                   )
//                 ],
//               ),
//             ),

//             // Centered Forgot Password Section
//             Expanded(
//               child: Center(
//                 child: Container(
//                   width: width * 0.9,
//                   padding: EdgeInsets.all(width * 0.06),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Forgot Password",
//                         style: TextStyle(
//                           color: Color(0xFF2D5948),
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       SizedBox(height: height * 0.03),
//                       Text("Enter your email account to reset your password"),
//                       SizedBox(height: height * 0.03),
//                       TextFormField(
//                         decoration: InputDecoration(
//                           hintText: "Email Id",
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(color: Colors.teal),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: height * 0.025),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF007F8C),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           onPressed: () {},
//                           child: const Text(
//                             "Reset password",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:staymitra/UserLogin/login.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 126, 140), // Start color
                    Color(0xFF57BDBF), // End color
                  ],
                  begin: Alignment.topCenter, // Gradient starts from the top
                  end: Alignment.bottomCenter, // Gradient ends at the bottom
                ),
              ),
            ),
            // Logo Section (Positioned at top left)
            Positioned(
              top: size.height * 0.05,
              left: size.width * 0.05,
              child: Logo(),
            ),
            // Forgot Password Section (Centered)
           Center(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
    child: SizedBox(
      height: size.height * 0.60, 
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ForgotPasswordText(),
            SizedBox(height: size.height * 0.02),
            EmailInputField(),
            SizedBox(height: size.height * 0.04),
            ResetPasswordButton(),
            SizedBox(height: size.height * 0.02),
            SignInLink(),
          ],
        ),
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}

class Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'staymithra',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class ForgotPasswordText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const  Color(0xFF2D5948),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your email account to reset your password',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: const  Color(0xFF2D5948),
          ),
        ),
      ],
    );
  }
}

class EmailInputField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email or Phone Number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      ),
    );
  }
}

class ResetPasswordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007F8C), // Button color
        minimumSize: Size(double.infinity, 50), // Full-width button
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        // Handle password reset
      },
      child: Text(
        'Reset Password',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInPage()));
      },
      child: Text(
        'Sign In',
        style: TextStyle(
          color: const Color(0xFF007F8C),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
