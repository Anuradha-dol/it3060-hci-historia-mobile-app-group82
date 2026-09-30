import 'package:flutter/material.dart';

import '../widgets/historia_components.dart';

// =====================================================================
// NOTIFICATIONS SCREEN
// =====================================================================

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F9F6),
      body: SafeArea(
        child: NotificationsContent(
          standalone: true,
        ),
      ),
    );
  }
}

// =====================================================================
// NOTIFICATIONS CONTENT
// =====================================================================

class NotificationsContent extends StatelessWidget {
  final bool standalone;
  final String roleLabel;

  const NotificationsContent({
    super.key,
    this.standalone = false,
    this.roleLabel = 'ACCOUNT',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F9F6),

      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,

        children: [
          // ===========================================================
          // HERO HEADER
          // ===========================================================
          _NotificationsHero(
            roleLabel: roleLabel,
            standalone: standalone,
          ),

          // ===========================================================
          // CONTENT
          // ===========================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              28,
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,

              children: [
                // =====================================================
                // SECTION TITLE
                // =====================================================
                const _SectionHeader(
                  eyebrow: 'YOUR UPDATES',
                  title: 'Notification centre',
                  subtitle:
                  'Important HISTORIA updates will be shown here when notification support is available.',
                ),

                const SizedBox(
                  height: 13,
                ),

                // =====================================================
                // STATUS CARD
                // =====================================================
                const _NotificationStatusCard(),

                const SizedBox(
                  height: 18,
                ),

                // =====================================================
                // EMPTY STATE
                // =====================================================
                const _NotificationEmptyState(),

                const SizedBox(
                  height: 18,
                ),

                // =====================================================
                // INFO NOTE
                // =====================================================
                const _BackendInfoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// HERO
// =====================================================================

class _NotificationsHero extends StatelessWidget {
  final String roleLabel;
  final bool standalone;

  const _NotificationsHero({
    required this.roleLabel,
    required this.standalone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        12,
        24,
      ),

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9FCFA),
            Color(0xFFE8F4EC),
            Color(0xFFD8EBDD),
          ],
        ),
      ),

      child: Stack(
        children: [
          // ===========================================================
          // DECORATIVE CIRCLE
          // ===========================================================
          Positioned(
            right: -35,
            bottom: -55,

            child: Container(
              width: 165,
              height: 165,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF176D4E)
                    .withValues(
                  alpha: 0.06,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // =======================================================
              // TOP BRAND ROW
              // =======================================================
              Row(
                children: [
                  const _HistoriaLogo(),

                  const SizedBox(
                    width: 9,
                  ),

                  const Expanded(
                    child: _HistoriaBrand(),
                  ),

                  if (standalone)
                    HistoriaIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.maybePop(
                          context,
                        );
                      },
                    ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // =======================================================
              // ROLE LABEL
              // =======================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.70,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),

                  border: Border.all(
                    color: const Color(
                      0xFFD2E6DA,
                    ),
                  ),
                ),

                child: Text(
                  '$roleLabel / NOTIFICATIONS',

                  style: const TextStyle(
                    color: Color(
                      0xFF347258,
                    ),

                    fontSize: 7.5,

                    letterSpacing: 1,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =======================================================
              // TITLE
              // =======================================================
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,

                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Color(
                              0xFF143C2F,
                            ),
                            fontSize: 27,
                            height: 1,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),

                        SizedBox(
                          height: 7,
                        ),

                        Text(
                          'Your account updates in one place.',
                          style: TextStyle(
                            color: Color(
                              0xFF6C8176,
                            ),
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 62,
                    height: 62,

                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white.withValues(
                        alpha: 0.72,
                      ),

                      shape:
                      BoxShape.circle,

                      border:
                      Border.all(
                        color:
                        const Color(
                          0xFFCFE4D7,
                        ),
                      ),
                    ),

                    child: const Icon(
                      Icons
                          .notifications_none_rounded,

                      size: 29,

                      color: Color(
                        0xFF176D4E,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// SECTION HEADER
// =====================================================================

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          eyebrow,

          style: const TextStyle(
            color: Color(
              0xFF4C836A,
            ),

            fontSize: 7.5,

            letterSpacing: 1.1,

            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          title,

          style: const TextStyle(
            color: Color(
              0xFF143C2F,
            ),

            fontSize: 16,

            fontWeight:
            FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,

          style: const TextStyle(
            color: Color(
              0xFF78887F,
            ),

            fontSize: 9,

            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// STATUS CARD
// =====================================================================

class _NotificationStatusCard
    extends StatelessWidget {
  const _NotificationStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: const Color(
            0xFFDCE8E1,
          ),
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(
              0x09083A2A,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
            const BoxDecoration(
              color: Color(
                0xFFE5F2E9,
              ),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .notifications_active_outlined,
              size: 21,
              color: Color(
                0xFF176D4E,
              ),
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  'Notification service',
                  style: TextStyle(
                    color: Color(
                      0xFF173E31,
                    ),
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'Waiting for backend notification support.',
                  style: TextStyle(
                    color: Color(
                      0xFF74857C,
                    ),
                    fontSize: 8.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),

            decoration:
            BoxDecoration(
              color: const Color(
                0xFFFFF5DE,
              ),

              borderRadius:
              BorderRadius.circular(
                20,
              ),

              border: Border.all(
                color: const Color(
                  0xFFF0DDAA,
                ),
              ),
            ),

            child: const Text(
              'NOT READY',

              style: TextStyle(
                color: Color(
                  0xFF94681C,
                ),

                fontSize: 6.5,

                letterSpacing: 0.5,

                fontWeight:
                FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// EMPTY STATE
// =====================================================================

class _NotificationEmptyState
    extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        30,
        22,
        28,
      ),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFFFFFFFF,
            ),
            Color(
              0xFFF1F8F4,
            ),
          ],
        ),

        borderRadius:
        BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: const Color(
            0xFFDCE8E1,
          ),
        ),
      ),

      child: Column(
        children: [
          // ===========================================================
          // ICON
          // ===========================================================
          Stack(
            alignment:
            Alignment.center,

            children: [
              Container(
                width: 96,
                height: 96,

                decoration:
                const BoxDecoration(
                  color: Color(
                    0xFFE7F3EA,
                  ),
                  shape: BoxShape.circle,
                ),
              ),

              Container(
                width: 67,
                height: 67,

                decoration:
                BoxDecoration(
                  color: Colors.white,

                  shape: BoxShape.circle,

                  border: Border.all(
                    color: const Color(
                      0xFFD1E6D9,
                    ),
                  ),
                ),

                child: const Icon(
                  Icons
                      .notifications_none_rounded,

                  size: 31,

                  color: Color(
                    0xFF176D4E,
                  ),
                ),
              ),

              Positioned(
                right: 7,
                top: 9,

                child: Container(
                  width: 20,
                  height: 20,

                  decoration:
                  const BoxDecoration(
                    color: Color(
                      0xFF176D4E,
                    ),
                    shape:
                    BoxShape.circle,
                  ),

                  child:
                  const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color:
                    Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'No notifications yet',
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Color(
                0xFF143C2F,
              ),
              fontSize: 17,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'There are no notification records to display right now.',
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Color(
                0xFF71847A,
              ),
              fontSize: 9.5,
              height: 1.45,
            ),
          ),

          const SizedBox(
            height: 17,
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            decoration:
            BoxDecoration(
              color: const Color(
                0xFFE9F4ED,
              ),

              borderRadius:
              BorderRadius.circular(
                30,
              ),
            ),

            child: const Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Icon(
                  Icons
                      .check_circle_outline_rounded,
                  size: 14,
                  color: Color(
                    0xFF247255,
                  ),
                ),

                SizedBox(
                  width: 5,
                ),

                Text(
                  'You are all caught up',
                  style: TextStyle(
                    color: Color(
                      0xFF247255,
                    ),
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w700,
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
// BACKEND INFO CARD
// =====================================================================

class _BackendInfoCard extends StatelessWidget {
  const _BackendInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        13,
      ),

      decoration: BoxDecoration(
        color: const Color(
          0xFFF0F6F2,
        ),

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: const Color(
            0xFFD8E7DE,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: Color(
              0xFF3D725D,
            ),
          ),

          SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  'Backend integration',
                  style: TextStyle(
                    color: Color(
                      0xFF315E4C,
                    ),
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'The current backend does not expose a notification endpoint. This screen will remain empty until that service is available.',
                  style: TextStyle(
                    color: Color(
                      0xFF6E8177,
                    ),
                    fontSize: 8.5,
                    height: 1.4,
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
// HISTORIA LOGO
// =====================================================================

class _HistoriaLogo extends StatelessWidget {
  const _HistoriaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,

      decoration: BoxDecoration(
        color: const Color(
          0xFFE4F2E9,
        ),

        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),

      child: const Icon(
        Icons.eco_outlined,
        size: 20,
        color: Color(
          0xFF176D4E,
        ),
      ),
    );
  }
}

// =====================================================================
// HISTORIA BRAND
// =====================================================================

class _HistoriaBrand extends StatelessWidget {
  const _HistoriaBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          'HISTORIA',

          style: TextStyle(
            color: Color(
              0xFF153D30,
            ),

            fontSize: 13.5,

            fontWeight:
            FontWeight.w900,

            letterSpacing: 0.3,
          ),
        ),

        SizedBox(
          height: 1,
        ),

        Text(
          'EXPLORE HISTORY · FIND YOUR GUIDE',

          style: TextStyle(
            color: Color(
              0xFF73857C,
            ),

            fontSize: 6.1,

            letterSpacing: 0.2,

            fontWeight:
            FontWeight.w600,
          ),
        ),
      ],
    );
  }
}