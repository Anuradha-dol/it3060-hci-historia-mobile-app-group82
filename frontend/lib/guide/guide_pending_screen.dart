import 'package:flutter/material.dart';

import '../auth/guide_resubmit_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/historia_components.dart';

class GuidePendingScreen extends StatelessWidget {
  const GuidePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F3),

      body: Stack(
        children: [
          // =========================================================
          // BACKGROUND
          // =========================================================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF9FCF9),
                  Color(0xFFF1F8F4),
                  Color(0xFFEAF5EF),
                ],
              ),
            ),
          ),

          // =========================================================
          // SOFT DECORATION
          // =========================================================
          Positioned(
            top: 120,
            right: -75,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD3EBDD)
                    .withValues(alpha: 0.28),
              ),
            ),
          ),

          Positioned(
            top: 350,
            left: -95,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDDEFE5)
                    .withValues(alpha: 0.24),
              ),
            ),
          ),

          // =========================================================
          // PAGE
          // =========================================================
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                ),
                child: Column(
                  children: [
                    // =================================================
                    // HEADER
                    // =================================================
                    const HistoriaHeader(
                      title: 'Application submitted',
                      subtitle:
                      'Your guide account is waiting for admin approval.',
                      eyebrow: 'GUIDE APPLICATION',
                      icon: Icons.hourglass_top_outlined,
                    ),

                    // =================================================
                    // CONTENT
                    // =================================================
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          10,
                          16,
                          5,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            // =========================================
                            // PENDING REVIEW CARD
                            // =========================================
                            const _PendingReviewCard(),

                            const SizedBox(
                              height: 12,
                            ),

                            // =========================================
                            // NEED CHANGES CARD
                            // =========================================
                            const _NeedChangesCard(),

                            const SizedBox(
                              height: 17,
                            ),

                            // =========================================
                            // APPROVAL NOTE
                            // =========================================
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F8F4),
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                  const Color(0xFFD4E7DC),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDDEFE5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons
                                          .admin_panel_settings_outlined,
                                      size: 14,
                                      color:
                                      Color(0xFF277154),
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Flexible(
                                    child: Text(
                                      'Your guide access will activate after admin approval.',
                                      textAlign:
                                      TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color:
                                        const Color(
                                          0xFF587066,
                                        ),
                                        fontSize: 10.5,
                                        fontWeight:
                                        FontWeight.w600,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            // =========================================
                            // BACK TO LOGIN
                            // =========================================
                            HistoriaButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const LoginScreen(),
                                  ),
                                      (route) => false,
                                );
                              },
                              icon: Icons.login,
                              label: 'Back to Login',
                            ),

                            const SizedBox(
                              height: 9,
                            ),

                            // =========================================
                            // RESUBMIT APPLICATION
                            // =========================================
                            HistoriaOutlineButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const GuideResubmitScreen(),
                                  ),
                                );
                              },
                              icon: Icons.refresh_rounded,
                              label:
                              'Resubmit Application',
                            ),

                            const Spacer(),

                            // =========================================
                            // BOTTOM NOTE
                            // =========================================
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color:
                                    Color(0xFF56816B),
                                  ),

                                  const SizedBox(
                                    width: 6,
                                  ),

                                  Flexible(
                                    child: Text(
                                      'Your application is safely stored while the review is pending.',
                                      textAlign:
                                      TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color:
                                        const Color(
                                          0xFF61766C,
                                        ),
                                        fontSize: 10.2,
                                        fontWeight:
                                        FontWeight.w500,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // =================================================
                    // FOOTER IMAGE
                    // =================================================
                    const _GuidePendingFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// PENDING REVIEW CARD
// =====================================================================

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        13,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBF0),
            Color(0xFFFFF4D9),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF0DCA7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A7A5A18),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ===========================================================
          // ICON
          // ===========================================================
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE9AE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFD88B00),
              size: 23,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ===========================================================
          // TEXT
          // ===========================================================
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6A8),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Color(0xFFAA6500),
                      fontSize: 8.8,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Pending admin review',
                  style: TextStyle(
                    color: Color(0xFF123F32),
                    fontSize: 13,
                    height: 1.1,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'You can sign in after an admin approves your guide application.',
                  style: TextStyle(
                    color: Color(0xFF687B72),
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight:
                    FontWeight.w500,
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

// =====================================================================
// NEED CHANGES CARD
// =====================================================================

class _NeedChangesCard extends StatelessWidget {
  const _NeedChangesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        12,
        13,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFCFE5D9),
        ),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ===========================================================
          // ICON
          // ===========================================================
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEFE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF227454),
              size: 23,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ===========================================================
          // TEXT
          // ===========================================================
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'NEED CHANGES?',
                  style: TextStyle(
                    color: Color(0xFF257054),
                    fontSize: 8.5,
                    letterSpacing: 0.6,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Update and resubmit',
                  style: TextStyle(
                    color: Color(0xFF123F32),
                    fontSize: 12.5,
                    height: 1.1,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'If an admin marks your application as needs work, use resubmit to send updated guide details.',
                  style: TextStyle(
                    color: Color(0xFF687B72),
                    fontSize: 10.2,
                    height: 1.35,
                    fontWeight:
                    FontWeight.w500,
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

// =====================================================================
// GUIDE PENDING FOOTER
// =====================================================================

class _GuidePendingFooter extends StatelessWidget {
  const _GuidePendingFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,

      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 10,
            child: ClipPath(
              clipper:
              _PendingFooterClipper(),
              child: Image.asset(
                'assets/images/historia_pending_footer.png',
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                alignment:
                const Alignment(
                  0,
                  0.35,
                ),
                filterQuality:
                FilterQuality.high,
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return Container(
                    color:
                    const Color(
                      0xFFEAF5EE,
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 30,
              child: CustomPaint(
                painter:
                _PendingWavePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// FOOTER CLIP
// =====================================================================

class _PendingFooterClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(
      0,
      19,
    );

    path.quadraticBezierTo(
      size.width * 0.18,
      5,
      size.width * 0.43,
      12,
    );

    path.quadraticBezierTo(
      size.width * 0.70,
      25,
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
      covariant CustomClipper<Path> oldClipper,
      ) {
    return false;
  }
}

// =====================================================================
// FOOTER WAVES
// =====================================================================

class _PendingWavePainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final lightPaint = Paint()
      ..color =
      const Color(0xFFDCEFE5)
      ..style =
          PaintingStyle.fill;

    final darkPaint = Paint()
      ..color =
      const Color(0xFFC6E2D3)
      ..style =
          PaintingStyle.fill;

    // ================================================================
    // LIGHT WAVE
    // ================================================================
    final path1 = Path();

    path1.moveTo(
      0,
      20,
    );

    path1.quadraticBezierTo(
      size.width * 0.20,
      5,
      size.width * 0.46,
      13,
    );

    path1.quadraticBezierTo(
      size.width * 0.74,
      27,
      size.width,
      9,
    );

    path1.lineTo(
      size.width,
      19,
    );

    path1.quadraticBezierTo(
      size.width * 0.74,
      33,
      size.width * 0.46,
      25,
    );

    path1.quadraticBezierTo(
      size.width * 0.20,
      16,
      0,
      30,
    );

    path1.close();

    canvas.drawPath(
      path1,
      lightPaint,
    );

    // ================================================================
    // SECOND WAVE
    // ================================================================
    final path2 = Path();

    path2.moveTo(
      0,
      26,
    );

    path2.quadraticBezierTo(
      size.width * 0.23,
      17,
      size.width * 0.51,
      24,
    );

    path2.quadraticBezierTo(
      size.width * 0.78,
      34,
      size.width,
      18,
    );

    path2.lineTo(
      size.width,
      25,
    );

    path2.quadraticBezierTo(
      size.width * 0.78,
      37,
      size.width * 0.51,
      31,
    );

    path2.quadraticBezierTo(
      size.width * 0.23,
      23,
      0,
      34,
    );

    path2.close();

    canvas.drawPath(
      path2,
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