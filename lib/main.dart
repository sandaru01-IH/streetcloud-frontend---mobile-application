import 'package:flutter/material.dart';

import 'api/client.dart';
import 'screens/home_shell.dart';
import 'screens/register_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.api, required this.theme, required this.themeMode, required super.child});
  final ApiClient api;
  final ThemeController theme;
  final ThemeMode themeMode;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => api != oldWidget.api || themeMode != oldWidget.themeMode;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final theme = ThemeController();
  await api.load();
  await theme.load();
  runApp(StreetCloudApp(api: api, theme: theme));
}

class StreetCloudApp extends StatelessWidget {
  const StreetCloudApp({super.key, required this.api, required this.theme});
  final ApiClient api;
  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        return AppScope(
          api: api,
          theme: theme,
          themeMode: theme.mode,
          child: MaterialApp(
            title: 'Street Cloud',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: ThemeData(brightness: Brightness.light, fontFamily: 'Roboto', colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C3D5A))),
            darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'Roboto', colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4B483), brightness: Brightness.dark)),
            home: const WelcomeScreen(),
            routes: {
              '/sign-in': (_) => const SignInScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const HomeShell(),
            },
          ),
        );
      },
    );
  }
}
