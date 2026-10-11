import 'package:flutter/material.dart';

import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _mark;
  late final AnimationController _title;
  late final AnimationController _group;
  late final AnimationController _place;
  late final AnimationController _cover;
  late final CurvedAnimation _markEase;
  late final CurvedAnimation _titleEase;
  late final CurvedAnimation _groupEase;
  late final CurvedAnimation _placeEase;

  @override
  void initState() {
    super.initState();
    _mark = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _title = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
    _group = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _place = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _cover = AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);
    _markEase = CurvedAnimation(parent: _mark, curve: Curves.easeOutCubic);
    _titleEase = CurvedAnimation(parent: _title, curve: Curves.easeOutCubic);
    _groupEase = CurvedAnimation(parent: _group, curve: Curves.easeOutCubic);
    _placeEase = CurvedAnimation(parent: _place, curve: Curves.easeOutCubic);
    _mark.forward();
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _title.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 560), () {
      if (mounted) _group.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 980), () {
      if (mounted) _place.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 3400), () {
      if (mounted) _cover.reverse();
    });
    Future<void>.delayed(const Duration(milliseconds: 3850), _leave);
  }

  void _leave() {
    if (!mounted) return;
    final api = AppScope.of(context).api;
    Navigator.of(context).pushReplacementNamed(api.accessToken == null ? '/sign-in' : '/home');
  }

  @override
  void dispose() {
    _markEase.dispose();
    _titleEase.dispose();
    _groupEase.dispose();
    _placeEase.dispose();
    _mark.dispose();
    _title.dispose();
    _group.dispose();
    _place.dispose();
    _cover.dispose();
    super.dispose();
  }

  TextStyle _face(Color color, double size, {FontWeight weight = FontWeight.w400, double height = 1.3, double spacing = 0}) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      fontFamily: 'Roboto',
      decoration: TextDecoration.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: FadeTransition(
        opacity: _cover,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.backgroundTop, palette.backgroundMid, palette.backgroundBottom],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(top: -40, right: -70, child: _Glow(size: 240, color: palette.primary, opacity: 0.16)),
                  const Positioned(bottom: 40, left: -80, child: _Glow(size: 220, color: Color(0xFFD4B483), opacity: 0.2)),
                  Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _markEase,
                                child: ScaleTransition(
                                  scale: Tween(begin: 0.86, end: 1.0).animate(_markEase),
                                  child: const _Mark(),
                                ),
                              ),
                              const SizedBox(height: 26),
                              FadeTransition(
                                opacity: _titleEase,
                                child: AnimatedBuilder(
                                  animation: _titleEase,
                                  builder: (context, child) => Transform.translate(
                                    offset: Offset(0, (1 - _titleEase.value) * 12),
                                    child: child,
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Street Cloud', style: _face(palette.text, 34, weight: FontWeight.w700, height: 1.05, spacing: -0.6)),
                                      const SizedBox(height: 14),
                                      AnimatedBuilder(
                                        animation: _titleEase,
                                        builder: (context, child) => Transform.scale(
                                          scaleX: _titleEase.value.clamp(0.001, 1),
                                          child: child,
                                        ),
                                        child: Container(
                                          width: 46,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5B400),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                        child: FadeTransition(
                          opacity: _groupEase,
                          child: AnimatedBuilder(
                            animation: _groupEase,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, (1 - _groupEase.value) * 18),
                              child: child,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: palette.border),
                                boxShadow: const [BoxShadow(color: Color(0x14071426), blurRadius: 16, offset: Offset(0, 8))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                                child: Column(
                                  children: [
                                    Text('SmartMind UI & AI Group', textAlign: TextAlign.center, style: _face(palette.text, 14, weight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Text('Urban Simulation Lab', textAlign: TextAlign.center, style: _face(palette.muted, 13)),
                                    const SizedBox(height: 12),
                                    Container(width: 36, height: 1, color: palette.border),
                                    const SizedBox(height: 12),
                                    FadeTransition(
                                      opacity: _placeEase,
                                      child: AnimatedBuilder(
                                        animation: _placeEase,
                                        builder: (context, child) => Transform.translate(
                                          offset: Offset(0, (1 - _placeEase.value) * 10),
                                          child: child,
                                        ),
                                        child: Column(
                                          children: [
                                            Text('Department of Town & Country Planning', textAlign: TextAlign.center, style: _face(palette.muted, 13)),
                                            const SizedBox(height: 3),
                                            Text('University of Moratuwa, Sri Lanka', textAlign: TextAlign.center, style: _face(palette.text, 13, weight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return const ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        -1, -1, -1, 3, 0,
      ]),
      child: SizedBox(
        width: 168,
        height: 140,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 780,
            height: 640,
            child: Stack(
              children: [
                Positioned(
                  left: -340,
                  top: -120,
                  width: 1448,
                  height: 1086,
                  child: Image(
                    image: AssetImage('assets/logo.png'),
                    fit: BoxFit.fill,
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

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
