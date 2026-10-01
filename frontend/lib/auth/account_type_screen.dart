import 'package:flutter/material.dart';

import '../widgets/historia_components.dart';
import 'guide_signup_screen.dart';
import 'signup_screen.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  static const Color pageBg = Color(0xFFF7FBF8);
  static const Color darkGreen = Color(0xFF0D4A37);
  static const Color primaryGreen = Color(0xFF176C4B);
  static const Color mutedText = Color(0xFF6D8078);

  static const Color cardStart = Color(0xFFF5FBF7);
  static const Color cardEnd = Color(0xFFEAF6F0);
  static const Color border = Color(0xFFCFE3D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Positioned(
                  top: 150,
                  right: -30,
                  child: Icon(
                    Icons.eco_outlined,
                    size: 110,
                    color: primaryGreen.withValues(alpha: 0.035),
                  ),
                ),

                Positioned(
                  bottom: 115,
                  left: -40,
                  child: Icon(
                    Icons.eco_outlined,
                    size: 120,
                    color: primaryGreen.withValues(alpha: 0.035),
                  ),
                ),

                Column(
                  children: [
                    _HistoriaHeader(onClose: () => Navigator.maybePop(context)),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'REGISTRATION / CHOOSE YOUR PATH',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Your journey starts here.',
                              style: TextStyle(
                                color: darkGreen,
                                fontSize: 29,
                                height: 1.04,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),

                            const SizedBox(height: 7),

                            const Text(
                              'Choose how you would like to join HISTORIA.',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Divider(height: 1, color: Color(0xFFD9E7E0)),

                            const SizedBox(height: 14),

                            _RoleCard(
                              eyebrow: 'EXPLORE',
                              title: 'Join as a tourist',
                              description:
                                  'Discover historic places with a knowledgeable local guide.',
                              action: 'CREATE TOURIST ACCOUNT',
                              imagePath: 'assets/images/tourist_role_bg.png',
                              imageWidth: 96,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            _RoleCard(
                              eyebrow: 'LEAD',
                              title: 'Join as a local guide',
                              description:
                                  'Share local stories and welcome travellers.',
                              action: 'APPLY TO BECOME A GUIDE',
                              imagePath: 'assets/images/guide_role_bg.png',
                              imageWidth: 98,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GuideSignupScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            const _DifferenceBox(),

                            const Spacer(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    Navigator.maybePop(context);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    const _HeritageFooter(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoriaHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _HistoriaHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FCF9),
        border: Border(bottom: BorderSide(color: Color(0xFFDDE9E3))),
      ),
      child: HistoriaBrandRow(
        actions: [
          HistoriaIconButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final String action;
  final String imagePath;
  final double imageWidth;
  final VoidCallback onTap;

  const _RoleCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.action,
    required this.imagePath,
    required this.imageWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AccountTypeScreen.cardStart,
                  AccountTypeScreen.cardEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AccountTypeScreen.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D123F30),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -18,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD7EDE2).withValues(alpha: 0.45),
                      ),
                      child: Icon(
                        Icons.eco_outlined,
                        size: 42,
                        color: AccountTypeScreen.primaryGreen.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 3, 2),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              imagePath,
                              width: imageWidth,
                              height: 136,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 13, 13, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4EBDD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  eyebrow,
                                  style: const TextStyle(
                                    color: AccountTypeScreen.primaryGreen,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AccountTypeScreen.darkGreen,
                                  fontSize: 19,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AccountTypeScreen.mutedText,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),

                              const Spacer(),

                              const Divider(
                                height: 1,
                                thickness: 0.8,
                                color: Color(0xFFC2D9CC),
                              ),

                              const SizedBox(height: 7),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      action,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AccountTypeScreen.primaryGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD0E8D9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: AccountTypeScreen.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifferenceBox extends StatelessWidget {
  const _DifferenceBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5F3EB), Color(0xFFF0F8F4)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1E5DA)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2D8A62),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 31,
            height: 31,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD3EADF),
            ),
            child: const Icon(
              Icons.info_outline,
              size: 18,
              color: AccountTypeScreen.primaryGreen,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ONE IMPORTANT DIFFERENCE',
                  style: TextStyle(
                    color: AccountTypeScreen.darkGreen,
                    fontSize: 8.6,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Tourists verify email. Guides must also pass an admin review before access.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AccountTypeScreen.mutedText,
                    fontSize: 10.2,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeritageFooter extends StatelessWidget {
  const _HeritageFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            top: 25,
            child: ClipPath(
              clipper: _FooterClipper(),
              child: Image.asset(
                'assets/images/account_type_footer_4k.webp',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.12),
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 45),
              painter: _FooterWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 16);

    path.quadraticBezierTo(size.width * 0.20, 0, size.width * 0.45, 12);

    path.quadraticBezierTo(size.width * 0.72, 27, size.width, 5);

    path.lineTo(size.width, size.height);

    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _FooterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..color = const Color(0xFFE5F3EB)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFFCBE5D7)
      ..style = PaintingStyle.fill;

    final path1 = Path();

    path1.moveTo(0, 24);

    path1.quadraticBezierTo(size.width * 0.22, 4, size.width * 0.46, 15);

    path1.quadraticBezierTo(size.width * 0.74, 30, size.width, 8);

    path1.lineTo(size.width, 26);

    path1.quadraticBezierTo(size.width * 0.73, 40, size.width * 0.46, 30);

    path1.quadraticBezierTo(size.width * 0.21, 19, 0, 35);

    path1.close();

    canvas.drawPath(path1, lightPaint);

    final path2 = Path();

    path2.moveTo(0, 33);

    path2.quadraticBezierTo(size.width * 0.24, 20, size.width * 0.50, 29);

    path2.quadraticBezierTo(size.width * 0.78, 40, size.width, 21);

    path2.lineTo(size.width, 31);

    path2.quadraticBezierTo(size.width * 0.77, 44, size.width * 0.50, 37);

    path2.quadraticBezierTo(size.width * 0.24, 28, 0, 40);

    path2.close();

    canvas.drawPath(path2, darkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
