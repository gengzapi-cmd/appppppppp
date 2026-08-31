import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/snapcat_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SnapCatFlutterApp());
}

class SnapCatFlutterApp extends StatefulWidget {
  const SnapCatFlutterApp({super.key});

  @override
  State<SnapCatFlutterApp> createState() => _SnapCatFlutterAppState();
}

class _SnapCatFlutterAppState extends State<SnapCatFlutterApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapCat Video Downloader',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF4444),
          brightness: Brightness.light,
          primary: const Color(0xFFEF4444),
          secondary: const Color(0xFFDC2626),
          background: const Color(0xFFF8FAFC),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF4444),
          brightness: Brightness.dark,
          primary: const Color(0xFFEF4444),
          secondary: const Color(0xFFDC2626),
          background: const Color(0xFF090D16),
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF090D16),
      ),
      home: SnapCatAppScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
