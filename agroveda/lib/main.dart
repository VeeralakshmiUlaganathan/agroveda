import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart'; // ✅ IMPORTANT
import 'theme/app_theme.dart';
import 'screens/landing_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.dark);

final ValueNotifier<Locale> localeNotifier =
    ValueNotifier(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AgrovedaApp());
}

class AgrovedaApp extends StatelessWidget {
  const AgrovedaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, _) {
        return ValueListenableBuilder(
          valueListenable: localeNotifier,
          builder: (context, Locale locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: "AGROVEDA",

              locale: locale,
              themeMode: currentMode,

              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,

              home: SplashScreen(), // ✅ NO const
            );
          },
        );
      },
    );
  }
}