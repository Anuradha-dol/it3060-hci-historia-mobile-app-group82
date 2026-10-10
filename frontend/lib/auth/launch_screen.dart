import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/historia_header.dart';
import 'login_screen.dart';

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  static const Color _deepGreen = Color(0xFF0F3F2E);
  static const Color _mint = Color(0xFFBDE8CF);
  static const Color _gold = Color(0xFFF1C978);
  static const String _heroImage = 'assets/images/launch_hero_sigiriya.png';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: LaunchScreen._deepGreen,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _LaunchImageBackground(),
            const _LaunchScrim(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 690;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      compact ? 12 : 18,
                      20,
                      compact ? 18 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _LaunchBrandBar(),
                        const Spacer(),
                        _LaunchCopy(compact: compact),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LaunchCopy extends StatelessWidget {
  final bool compact;

  const _LaunchCopy({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LaunchEyebrow(),
              SizedBox(height: compact ? 12 : 16),
              Text(
                "Discover Sri Lanka's timeless heritage.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 34 : 42,
                  height: 1.01,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 11 : 14),
              Text(
                'Explore ancient kingdoms, build your route, and connect '
                'with local guides for a richer journey.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: compact ? 13.5 : 15,
                  height: 1.48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 16 : 20),
              const _LaunchFeatureStrip(),
              SizedBox(height: compact ? 22 : 30),
              const _LaunchStartButton(),
              SizedBox(height: compact ? 11 : 14),
              const _LaunchFootnote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchEyebrow extends StatelessWidget {
  const _LaunchEyebrow();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.landscape_outlined,
                size: 14,
                color: LaunchScreen._gold,
              ),
              SizedBox(width: 7),
              Text(
                'Your island heritage companion',
                style: TextStyle(
                  color: LaunchScreen._gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchFeatureStrip extends StatelessWidget {
  const _LaunchFeatureStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LaunchChip(icon: Icons.travel_explore_rounded, text: 'Discover'),
        SizedBox(width: 8),
        _LaunchChip(icon: Icons.route_rounded, text: 'Plan'),
        SizedBox(width: 8),
        _LaunchChip(icon: Icons.groups_rounded, text: 'Connect'),
      ],
    );
  }
}

class _LaunchStartButton extends StatelessWidget {
  const _LaunchStartButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: LaunchScreen._gold,
            foregroundColor: LaunchScreen._deepGreen,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start exploring',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(width: 9),
              Icon(Icons.arrow_forward_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchFootnote extends StatelessWidget {
  const _LaunchFootnote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Curated heritage places, guides, routes, and travel moments',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.76),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LaunchImageBackground extends StatelessWidget {
  const _LaunchImageBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      LaunchScreen._heroImage,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) {
        return Image.asset(
          'assets/images/launch_bg.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        );
      },
    );
  }
}

class _LaunchScrim extends StatelessWidget {
  const _LaunchScrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.22),
                Colors.black.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.46),
                Colors.black.withValues(alpha: 0.92),
              ],
              stops: const [0, 0.30, 0.64, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                LaunchScreen._deepGreen.withValues(alpha: 0.50),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.10),
              ],
              stops: const [0, 0.58, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _LaunchBrandBar extends StatelessWidget {
  const _LaunchBrandBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Row(
            children: [
              HistoriaLogoMark(dark: true, size: 42),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'EXPLORE HISTORY / FIND YOUR GUIDE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFD5E9DF),
                        fontSize: 8,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaunchChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LaunchChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: LaunchScreen._mint, size: 17),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
