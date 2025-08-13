// import 'package:flutter/material.dart';
// import 'dart:async';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeIn;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     );

//     _fadeIn = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeIn,
//     );

//     _controller.forward();

//     Timer(const Duration(seconds: 2), () {
//       Navigator.pushReplacementNamed(context, '/get-started');

//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: const Color(0xFF007F8C),
//       body: Center(
//         child: FadeTransition(
//           opacity: _fadeIn,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset(
//                 'assets/logo/staymithra_logo.png',
//                 width: size.width * 0.5, 
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;   // rotates the gradient
  late final AnimationController _logoController; // fades/scales logo
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _scale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, .35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(.45, 1, curve: Curves.easeOutCubic),
    ));

    _logoController.forward();

    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      // keep your named route
      Navigator.pushReplacementNamed(context, '/get-started');
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // 1) Trendy animated sweep gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final angle = _bgController.value * 2 * math.pi;
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    // Brand-ish palette — tweak if needed
                    colors: const [
                      Color(0xFF007F8C),
                      Color(0xFF2D5948),
                      Color(0xFF00B3C6),
                      Color(0xFF007F8C),
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    transform: GradientRotation(angle),
                    center: Alignment.center,
                  ),
                ),
              );
            },
          ),
          // 2) Subtle floating bokeh blobs (soft, modern)
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final t = _bgController.value;
              return Stack(
                children: [
                  _blob(size, dx: .15 + .02 * math.sin(2 * math.pi * t), dy: .30, r: 90, opacity: .08),
                  _blob(size, dx: .85 + .02 * math.cos(2 * math.pi * t), dy: .25, r: 110, opacity: .07),
                  _blob(size, dx: .50, dy: .80 + .02 * math.sin(2 * math.pi * (t + .25)), r: 140, opacity: .06),
                ],
              );
            },
          ),
          // 3) Center content: glassmorphism + glowing logo + tagline
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: Tween<double>(begin: .88, end: 1).animate(_scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glass card with animated glow
                    AnimatedBuilder(
                      animation: _bgController,
                      builder: (context, child) {
                        final pulse = 8 + 6 * math.sin(_bgController.value * 2 * math.pi);
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.18),
                                blurRadius: 24 + pulse,
                                spreadRadius: 2 + (pulse / 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Image.asset(
                                'assets/logo/staymithra_logo.png',
                                width: size.width * 0.46,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 18),

                    SlideTransition(
                      position: _taglineSlide,
                      child: Opacity(
                        opacity: 0.95,
                        child: Text(
                          "Discover • Plan • Go",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Soft, blurred circle blob
  Widget _blob(Size size,
      {required double dx,
      required double dy,
      required double r,
      double opacity = .08}) {
    return Positioned(
      left: size.width * dx - r,
      top: size.height * dy - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(opacity),
              blurRadius: r * .9,
              spreadRadius: r * .2,
            ),
          ],
        ),
      ),
    );
  }
}
