import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeProvider with ChangeNotifier {
  final _box = GetStorage();
  final _key = 'isDarkMode';
  final _pokemonKey = 'isPokemonMode';

  ThemeProvider() {
    _loadFromPrefs();
  }

  bool _isDarkMode = false;
  bool _isPokemonMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isPokemonMode => _isPokemonMode;

  void _loadFromPrefs() {
    _isDarkMode = _box.read(_key) ?? false;
    _isPokemonMode = _box.read(_pokemonKey) ?? false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _box.write(_key, _isDarkMode);
    notifyListeners();
  }

  void togglePokemonMode() {
    _isPokemonMode = !_isPokemonMode;
    _box.write(_pokemonKey, _isPokemonMode);
    notifyListeners();
  }

  // Pokemon mode colors
  static const pokemonOrange = Color(0xFFFF6B35);
  static const pokemonRed = Color(0xFFE53935);
  static const pokemonYellow = Color(0xFFFFD54F);
  static const pokemonBlue = Color(0xFF42A5F5);

  ThemeData getTheme() {
    if (_isDarkMode) {
      // Premium Night Theme - Deep space with neon accents
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        canvasColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFF00E5FF),
          tertiary: Color(0xFFFF6B9D),
          surface: Color(0xFF161B22),
          error: Color(0xFFFF5252),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFFE6EDF3),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFE6EDF3),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF7C4DFF),
            elevation: 4,
            shadowColor: const Color(0xFF7C4DFF).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161B22),
          selectedItemColor: Color(0xFF7C4DFF),
          unselectedItemColor: Color(0xFF6E7681),
          type: BottomNavigationBarType.fixed,
          elevation: 16,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.bold, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFFE6EDF3), fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFFE6EDF3)),
          bodyMedium: TextStyle(color: Color(0xFF8B949E)),
          labelLarge: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w600),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF7C4DFF),
          textColor: Color(0xFFE6EDF3),
          titleTextStyle: TextStyle(
            color: Color(0xFFE6EDF3),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          subtitleTextStyle: TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 14,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE6EDF3)),
        dividerTheme: const DividerThemeData(color: Color(0xFF21262D), thickness: 1),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B22),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF21262D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF8B949E)),
          hintStyle: const TextStyle(color: Color(0xFF6E7681)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF21262D),
          contentTextStyle: const TextStyle(color: Color(0xFFE6EDF3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF7C4DFF);
            return const Color(0xFF6E7681);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF7C4DFF).withOpacity(0.4);
            return const Color(0xFF21262D);
          }),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
    } else {
      // Fresh Light Theme - Clean, modern, and vibrant
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
        canvasColor: const Color(0xFFF8FAFB),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00897B),
          secondary: Color(0xFF26A69A),
          tertiary: Color(0xFFFF7043),
          surface: Colors.white,
          error: Color(0xFFE53935),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1A1A2E),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF00897B),
            elevation: 3,
            shadowColor: const Color(0xFF00897B).withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00897B),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF1A1A2E)),
          bodyMedium: TextStyle(color: Color(0xFF5F6368)),
          labelLarge: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.w600),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF00897B),
          textColor: Color(0xFF1A1A2E),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          subtitleTextStyle: TextStyle(
            color: Color(0xFF5F6368),
            fontSize: 14,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF00897B);
            return Colors.grey.shade400;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF00897B).withOpacity(0.4);
            return Colors.grey.shade300;
          }),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      );
    }
  }
}
