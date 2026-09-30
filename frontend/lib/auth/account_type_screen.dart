import 'package:flutter/material.dart';

import 'guide_signup_screen.dart';
import 'signup_screen.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  static const Color background = Color(0xFFFCFCF7);
  static const Color darkGreen = Color(0xFF0E4A37);
  static const Color primaryGreen = Color(0xFF176C4B);
  static const Color mediumGreen = Color(0xFF3B8C67);

  static const Color mint = Color(0xFFEDF8F2);
  static const Color border = Color(0xFFCEE3D8);
  static const Color muted = Color(0xFF71837A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Column(
              children: [
                _HistoriaHeader(
                  onClose: () {
                    Navigator.maybePop(context);
                  },
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      13,
                      18,
                      10,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'REGISTRATION / CHOOSE YOUR PATH',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.15,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Your journey starts here.',
                          style: TextStyle(
                            color: darkGreen,
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Choose how you would like to join HISTORIA.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Divider(
                          height: 1,
                          color: Color(0xFFE0EBE5),
                        ),

                        const SizedBox(height: 13),

                        _RoleCard(
                          eyebrow: 'EXPLORE',
                          title: 'Join as a tourist',
                          description:
                          'Discover historic places with a knowledgeable local guide.',
                          actionText:
                          'CREATE TOURIST ACCOUNT',
                          imagePath:
                          'assets/images/tourist_role_bg.png',
                          imageWidth: 94,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const SignupScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 11),

                        _RoleCard(
                          eyebrow: 'LEAD',
                          title: 'Join as a local guide',
                          description:
                          'Share local stories and welcome travellers.',
                          actionText:
                          'APPLY TO BECOME A GUIDE',
                          imagePath:
                          'assets/images/guide_role_bg.png',
                          imageWidth: 96,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const GuideSignupScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 11),

                        const _DifferenceBox(),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: muted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            InkWell(
                              borderRadius:
                              BorderRadius.circular(5),
                              onTap: () {
                                Navigator.maybePop(context);
                              },
                              child: const Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 2,
                                ),
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 11.5,
                                    fontWeight:
                                    FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const _HeritageFooter(),
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

  const _HistoriaHeader({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: const BoxDecoration(
        color: AccountTypeScreen.background,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2EBE6),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE9F7EF),
                  Color(0xFFD8EEE2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color:
              AccountTypeScreen.primaryGreen,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'HISTORIA',
                  style: TextStyle(
                    color:
                    AccountTypeScreen.darkGreen,
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'EXPLORE HISTORY / FIND YOUR GUIDE',
                  style: TextStyle(
                    color: AccountTypeScreen.muted,
                    fontSize: 6.7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
              BorderRadius.circular(9),
              onTap: onClose,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(9),
                  border: Border.all(
                    color: AccountTypeScreen.border,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color:
                  AccountTypeScreen.primaryGreen,
                  size: 19,
                ),
              ),
            ),
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
  final String actionText;

  final String imagePath;
  final double imageWidth;

  final VoidCallback onTap;

  const _RoleCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionText,
    required this.imagePath,
    required this.imageWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5FBF7),
                  Color(0xFFE8F5EE),
                ],
              ),
              borderRadius:
              BorderRadius.circular(16),
              border: Border.all(
                color: AccountTypeScreen.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C123F30),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
              BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Very subtle green decoration.
                  Positioned(
                    right: -22,
                    top: -22,
                    child: Icon(
                      Icons.eco_outlined,
                      size: 82,
                      color:
                      AccountTypeScreen.mediumGreen
                          .withValues(alpha: 0.045),
                    ),
                  ),

                  Row(
                    children: [
                      // New image already contains
                      // the person + mint heritage background.
                      SizedBox(
                        width: 112,
                        height: double.infinity,
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            4,
                            7,
                            1,
                            0,
                          ),
                          child: Align(
                            alignment:
                            Alignment.bottomCenter,
                            child: Image.asset(
                              imagePath,
                              width: imageWidth,
                              height: 127,
                              fit: BoxFit.contain,
                              alignment:
                              Alignment.bottomCenter,
                              filterQuality:
                              FilterQuality.high,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            2,
                            12,
                            11,
                            9,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration:
                                BoxDecoration(
                                  color:
                                  const Color(
                                    0xFFD7ECDF,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                                ),
                                child: Text(
                                  eyebrow,
                                  style:
                                  const TextStyle(
                                    color:
                                    AccountTypeScreen
                                        .primaryGreen,
                                    fontSize: 7.4,
                                    fontWeight:
                                    FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                title,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color:
                                  AccountTypeScreen
                                      .darkGreen,
                                  fontSize: 17.5,
                                  height: 1.05,
                                  fontWeight:
                                  FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                description,
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color:
                                  AccountTypeScreen
                                      .muted,
                                  fontSize: 10,
                                  height: 1.28,
                                ),
                              ),

                              const Spacer(),

                              const Divider(
                                height: 1,
                                thickness: 0.8,
                                color:
                                Color(0xFFC6DCCF),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      actionText,
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      const TextStyle(
                                        color:
                                        AccountTypeScreen
                                            .primaryGreen,
                                        fontSize: 8.2,
                                        fontWeight:
                                        FontWeight.w800,
                                        letterSpacing:
                                        0.3,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    width: 27,
                                    height: 27,
                                    decoration:
                                    const BoxDecoration(
                                      color:
                                      Color(0xFFD7ECDF),
                                      shape:
                                      BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons
                                          .arrow_forward_rounded,
                                      color:
                                      AccountTypeScreen
                                          .primaryGreen,
                                      size: 16,
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
      height: 66,
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE6F5ED),
            Color(0xFFF1F9F5),
          ],
        ),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD6E8DF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2D8A62),
              borderRadius:
              BorderRadius.circular(3),
            ),
          ),

          const SizedBox(width: 9),

          Container(
            width: 29,
            height: 29,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDAEEE4),
            ),
            child: const Icon(
              Icons.info_outline,
              size: 17,
              color:
              AccountTypeScreen.primaryGreen,
            ),
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'ONE IMPORTANT DIFFERENCE',
                  style: TextStyle(
                    color:
                    AccountTypeScreen.darkGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Tourists verify email. Guides must also pass an admin review before access.',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                    AccountTypeScreen.muted,
                    fontSize: 9.5,
                    height: 1.22,
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
      height: 138,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 15,
            child: ClipPath(
              clipper:
              _FooterWaveClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/account_type_footer_4k.webp',
                    fit: BoxFit.cover,
                    alignment:
                    const Alignment(0, 0.10),
                    filterQuality:
                    FilterQuality.high,
                  ),

                  Container(
                    decoration:
                    const BoxDecoration(
                      gradient:
                      LinearGradient(
                        begin:
                        Alignment.topCenter,
                        end:
                        Alignment.bottomCenter,
                        colors: [
                          Color(0x73FCFCF7),
                          Color(0x10FCFCF7),
                          Color(0x00124D3A),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 1,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
              child: CustomPaint(
                painter:
                _GreenWavePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterWaveClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(
      0,
      23,
    );

    path.quadraticBezierTo(
      size.width * 0.20,
      -2,
      size.width * 0.45,
      12,
    );

    path.quadraticBezierTo(
      size.width * 0.72,
      29,
      size.width,
      8,
    );

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
      covariant CustomClipper<Path>
      oldClipper,
      ) {
    return false;
  }
}

class _GreenWavePainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final lightPaint = Paint()
      ..color =
      const Color(0xFFE0F1E8)
      ..style =
          PaintingStyle.fill;

    final darkPaint = Paint()
      ..color =
      const Color(0xFFCBE5D8)
      ..style =
          PaintingStyle.fill;

    final lightPath = Path();

    lightPath.moveTo(
      0,
      25,
    );

    lightPath.quadraticBezierTo(
      size.width * 0.22,
      3,
      size.width * 0.48,
      16,
    );

    lightPath.quadraticBezierTo(
      size.width * 0.74,
      31,
      size.width,
      8,
    );

    lightPath.lineTo(
      size.width,
      24,
    );

    lightPath.quadraticBezierTo(
      size.width * 0.72,
      42,
      size.width * 0.48,
      29,
    );

    lightPath.quadraticBezierTo(
      size.width * 0.21,
      17,
      0,
      35,
    );

    lightPath.close();

    canvas.drawPath(
      lightPath,
      lightPaint,
    );

    final darkPath = Path();

    darkPath.moveTo(
      0,
      32,
    );

    darkPath.quadraticBezierTo(
      size.width * 0.25,
      15,
      size.width * 0.50,
      27,
    );

    darkPath.quadraticBezierTo(
      size.width * 0.78,
      38,
      size.width,
      19,
    );

    darkPath.lineTo(
      size.width,
      28,
    );

    darkPath.quadraticBezierTo(
      size.width * 0.78,
      45,
      size.width * 0.50,
      34,
    );

    darkPath.quadraticBezierTo(
      size.width * 0.25,
      24,
      0,
      38,
    );

    darkPath.close();

    canvas.drawPath(
      darkPath,
      darkPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}
