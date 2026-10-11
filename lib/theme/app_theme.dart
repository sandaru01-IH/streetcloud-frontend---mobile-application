import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.backgroundTop,
    required this.backgroundMid,
    required this.backgroundBottom,
    required this.surface,
    required this.wash,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.error,
  });

  final Brightness brightness;
  final Color backgroundTop;
  final Color backgroundMid;
  final Color backgroundBottom;
  final Color surface;
  final Color wash;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color error;

  static const light = AppPalette(
    brightness: Brightness.light,
    backgroundTop: Color(0xFFF8F6F3),
    backgroundMid: Color(0xFFF1F3F6),
    backgroundBottom: Color(0xFFD9E3EE),
    surface: Color(0xFFFFFCF8),
    wash: Color(0xFFF3EFE8),
    text: Color(0xFF1C1915),
    muted: Color(0xFF6F675E),
    border: Color(0xFFE6E0D6),
    primary: Color(0xFF1C3D5A),
    onPrimary: Color(0xFFFFFCF8),
    success: Color(0xFF1E6B4F),
    error: Color(0xFF8E3A3A),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    backgroundTop: Color(0xFF1C2836),
    backgroundMid: Color(0xFF141C27),
    backgroundBottom: Color(0xFF0B0E13),
    surface: Color(0xFF18212C),
    wash: Color(0xFF121820),
    text: Color(0xFFF6F3EE),
    muted: Color(0xFFC9C2B6),
    border: Color(0x33F6F3EE),
    primary: Color(0xFFD4B483),
    onPrimary: Color(0xFF1A140C),
    success: Color(0xFF8ED0B0),
    error: Color(0xFFF0A8A0),
  );
}

class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('streetcloud.theme');
    if (saved == 'light') mode = ThemeMode.light;
    if (saved == 'dark') mode = ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode value) async {
    if (mode == value) return;
    mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('streetcloud.theme', value == ThemeMode.dark ? 'dark' : 'light');
  }

  AppPalette paletteFor(BuildContext context) {
    final dark = mode == ThemeMode.dark || (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return dark ? AppPalette.dark : AppPalette.light;
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.palette, required this.child});
  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundTop, palette.backgroundMid, palette.backgroundBottom],
        ),
      ),
      child: child,
    );
  }
}
