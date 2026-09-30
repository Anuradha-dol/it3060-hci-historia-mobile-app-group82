import 'package:flutter/material.dart';

import 'login_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/launch_bg.png',
            fit: BoxFit.cover,
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 26,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 6),

                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF5E7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFF176C4B),
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'HISTORIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'EXPLORE HISTORY\nFIND YOUR GUIDE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.8,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dot(true),
                      const SizedBox(width: 7),
                      _dot(false),
                      const SizedBox(width: 7),
                      _dot(false),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Discover the stories\nthat shaped our world.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF176C4B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFF7ADFA8)
            : Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}
