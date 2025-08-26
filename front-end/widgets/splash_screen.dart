// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.deepPurple.shade50,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Logo with glowing effect
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 AnimatedBuilder(
//                   animation: _controller,
//                   builder: (_, child) {
//                     return Container(
//                       width: 140,
//                       height: 140,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.deepPurple.withOpacity(
//                           0.2 + 0.2 * math.sin(_controller.value * 2 * math.pi),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 Image.asset('assets/images/logo.png', width: 100),
//               ],
//             ),
//             const SizedBox(height: 30),

//             // Tagline
//             const Text(
//               "Welcome to BrickMMO",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.deepPurple,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Custom rotating loader
//             AnimatedBuilder(
//               animation: _controller,
//               builder: (_, __) {
//                 return Transform.rotate(
//                   angle: _controller.value * 2 * math.pi,
//                   child: const Icon(
//                     Icons.autorenew,
//                     size: 32,
//                     color: Colors.deepPurple,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // fade in & out loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Background colour fades in/out between two shades
        final backgroundColor = Color.lerp(
          Colors.deepPurple.shade400,
          Colors.deepPurple.shade100,
          (math.sin(_controller.value * math.pi) + 1) / 2, // smooth fade
        );

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 120),
                const SizedBox(height: 30),
                const Text(
                  "Welcome to BrickMMO",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
