import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lonelyreminder/firebase_options.dart';
import 'package:lonelyreminder/providers/theme_provider.dart';
import 'package:lonelyreminder/providers/auth_provider.dart' as auth;
import 'package:lonelyreminder/services/background_service.dart';
import 'package:lonelyreminder/services/database_service.dart';
import 'package:lonelyreminder/services/alarm_service.dart';
import 'package:lonelyreminder/services/google_auth_service.dart';
import 'package:lonelyreminder/pages/reminders_page.dart';
import 'package:lonelyreminder/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // Alarm package only supports iOS and Android
  if (Platform.isIOS || Platform.isAndroid) {
    await Alarm.init();
  }
  
  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    } catch (e) {
      developer.log('Firebase initialization skipped: $e', name: 'main', error: e);
  }
  await BackgroundService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _setupAlarmListeners();
  }

  void _setupAlarmListeners() {
    // Listen for when alarm starts ringing
    Alarm.ringStream.stream.listen((alarmSettings) async {
      developer.log('Alarm is ringing! ID: ${alarmSettings.id}, Title: ${alarmSettings.notificationSettings.title}', name: '_MyAppState');
      // Delete the event when alarm rings (user will dismiss it)
      await _deleteEventByAlarmId(alarmSettings.id);
    });

    // Listen for alarm updates (when alarm is stopped)
    Alarm.updateStream.stream.listen((alarmId) {
      developer.log('Alarm updated/stopped! ID: $alarmId', name: '_MyAppState');
    });
  }

  Future<void> _deleteEventByAlarmId(int alarmId) async {
    try {
      // Use O(1) query instead of O(n) iteration
      final event = await _databaseService.getEventByAlarmId(alarmId);
      if (event != null && event.id != null) {
        await _databaseService.deleteEvent(event.id!);
        developer.log('Event "${event.title}" deleted after alarm triggered', name: '_MyAppState');
      } else {
        developer.log('No event found with alarmId: $alarmId', name: '_MyAppState');
      }
    } catch (e) {
      developer.log('Error deleting event after alarm: $e', name: '_MyAppState', error: e);
    }
  }

  @override
  void dispose() {
    BackgroundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lonely Reminder',
      debugShowCheckedModeBanner: false,
      theme: context.watch<ThemeProvider>().getTheme(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1F3A)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF6C63FF)
              : Colors.teal,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF6B7280)
              : Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return const RemindersPage();
      case 1:
        return const SettingsPage();
      case 2:
        return _buildAccountPage();
      default:
        return const RemindersPage();
    }
  }

  Widget _buildAccountPage() {
    return const AccountPage();
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _totalReminders = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final db = DatabaseService();
    final events = await db.getAllEvents();
    setState(() {
      _totalReminders = events.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPokemonMode = context.watch<ThemeProvider>().isPokemonMode;
    final authProvider = context.watch<auth.AuthProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPokemonMode ? '🔥 Trainer Profile 🔥' : 'Account'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isPokemonMode ? Colors.black.withOpacity(0.5) : Colors.transparent,
        foregroundColor: isPokemonMode ? Colors.orange : null,
      ),
      extendBodyBehindAppBar: isPokemonMode,
      body: Container(
        decoration: isPokemonMode
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/charizard.jpg'),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0A0E27), const Color(0xFF1A1F3A)]
                      : [Colors.teal.shade50, Colors.white],
                ),
              ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Card
                _buildProfileCard(isDark, isPokemonMode, currentUser),
                const SizedBox(height: 16),
                // Stats Card
                _buildStatsCard(isDark, isPokemonMode, currentUser),
                const SizedBox(height: 16),
                // Actions Card
                _buildActionsCard(isDark, isPokemonMode, currentUser),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, bool isPokemonMode, User? currentUser) {
    final primaryColor = isPokemonMode
        ? const Color(0xFFFF6B35)
        : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B));

    return Card(
      elevation: isDark ? 8 : 4,
      color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isPokemonMode
            ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: isPokemonMode
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              )
            : null,
        child: Column(
          children: [
            // Avatar with glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: isPokemonMode ? Colors.black : (isDark ? const Color(0xFF161B22) : Colors.white),
                  backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
                  child: currentUser?.photoURL == null
                      ? Text(
                          isPokemonMode ? '🔥' : (currentUser?.displayName?.substring(0, 1).toUpperCase() ?? '👤'),
                          style: TextStyle(fontSize: isPokemonMode ? 40 : 36),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Name with gradient for Pokemon mode
            if (isPokemonMode)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFD54F)],
                ).createShader(bounds),
                child: Text(
                  currentUser?.displayName ?? 'Pokemon Trainer',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              )
            else
              Text(
                currentUser?.displayName ?? 'Guest User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E),
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 8),
            // Email or sign in prompt
            if (currentUser?.email != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      currentUser!.email!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isPokemonMode ? Colors.white70 : (isDark ? const Color(0xFF8B949E) : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                isPokemonMode ? 'Sign in to save your Pokemon!' : 'Sign in to sync your reminders',
                style: TextStyle(
                  fontSize: 14,
                  color: isPokemonMode ? Colors.white60 : (isDark ? const Color(0xFF8B949E) : Colors.grey[600]),
                ),
              ),
            if (isPokemonMode && currentUser != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('⭐', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 4),
                  Text(
                    'Elite Trainer',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('⭐', style: TextStyle(fontSize: 18)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark, bool isPokemonMode, User? currentUser) {
    return Card(
      elevation: isDark ? 8 : 4,
      color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isPokemonMode
            ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              emoji: isPokemonMode ? '🔥' : null,
              icon: isPokemonMode ? null : Icons.event_note,
              label: isPokemonMode ? 'Caught' : 'Reminders',
              value: '$_totalReminders',
              color: isPokemonMode
                  ? const Color(0xFFFF6B35)
                  : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
              isDark: isDark,
              isPokemonMode: isPokemonMode,
            ),
            Container(
              width: 1,
              height: 50,
              color: isPokemonMode
                  ? const Color(0xFFFF6B35).withOpacity(0.3)
                  : (isDark ? const Color(0xFF21262D) : Colors.grey.shade200),
            ),
            _buildStatItem(
              emoji: isPokemonMode ? '☁️' : null,
              icon: isPokemonMode ? null : Icons.cloud_done,
              label: 'Synced',
              value: currentUser != null ? '✓' : '✗',
              color: currentUser != null
                  ? (isPokemonMode ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50))
                  : Colors.grey,
              isDark: isDark,
              isPokemonMode: isPokemonMode,
            ),
            Container(
              width: 1,
              height: 50,
              color: isPokemonMode
                  ? const Color(0xFFFF6B35).withOpacity(0.3)
                  : (isDark ? const Color(0xFF21262D) : Colors.grey.shade200),
            ),
            _buildStatItem(
              emoji: isPokemonMode ? '📅' : null,
              icon: isPokemonMode ? null : Icons.calendar_month,
              label: 'Calendar',
              value: currentUser != null ? '✓' : '✗',
              color: currentUser != null
                  ? (isPokemonMode ? const Color(0xFF2196F3) : const Color(0xFF2196F3))
                  : Colors.grey,
              isDark: isDark,
              isPokemonMode: isPokemonMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    IconData? icon,
    String? emoji,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required bool isPokemonMode,
  }) {
    return Column(
      children: [
        // Show emoji for Pokemon mode, icon otherwise
        if (emoji != null && isPokemonMode)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          )
        else if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isPokemonMode ? Colors.white : (isDark ? const Color(0xFFE8E8F5) : Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPokemonMode ? Colors.white70 : (isDark ? const Color(0xFFB8B8D1) : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard(bool isDark, bool isPokemonMode, User? currentUser) {
    final primaryColor = isPokemonMode
        ? const Color(0xFFFF6B35)
        : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B));

    return Card(
      elevation: isDark ? 8 : 4,
      color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isPokemonMode
            ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          if (currentUser == null)
            _buildActionTile(
              emoji: isPokemonMode ? '⚡' : null,
              icon: Icons.login,
              title: isPokemonMode ? 'Join the Battle!' : 'Sign in with Google',
              subtitle: isPokemonMode ? 'Sync your Pokemon collection' : 'Sync reminders & calendar',
              color: primaryColor,
              isDark: isDark,
              isPokemonMode: isPokemonMode,
              onTap: () async {
                await context.read<auth.AuthProvider>().signIn();
                await _loadUserData();
              },
            )
          else
            _buildActionTile(
              emoji: isPokemonMode ? '🚪' : null,
              icon: Icons.logout,
              title: isPokemonMode ? 'Leave Arena' : 'Sign Out',
              subtitle: isPokemonMode ? 'Until next time, trainer!' : 'Disconnect your account',
              color: Colors.red,
              isDark: isDark,
              isPokemonMode: isPokemonMode,
              onTap: () async {
                await context.read<auth.AuthProvider>().signOut();
                await _loadUserData();
              },
            ),
          Divider(
            color: isPokemonMode
                ? const Color(0xFFFF6B35).withOpacity(0.3)
                : (isDark ? const Color(0xFF21262D) : Colors.grey.shade200),
            height: 1,
          ),
          _buildActionTile(
            emoji: isPokemonMode ? '🎮' : null,
            icon: Icons.info_outline,
            title: isPokemonMode ? 'Pokedex Version' : 'App Version',
            subtitle: isPokemonMode ? 'v1.0.0 🔥' : '1.0.0',
            color: isPokemonMode ? const Color(0xFF2196F3) : Colors.blue,
            isDark: isDark,
            isPokemonMode: isPokemonMode,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    String? emoji,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required bool isPokemonMode,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(isPokemonMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isPokemonMode
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: emoji != null && isPokemonMode
            ? Text(emoji, style: const TextStyle(fontSize: 22))
            : Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isPokemonMode ? Colors.white : (isDark ? const Color(0xFFE6EDF3) : Colors.black87),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isPokemonMode ? Colors.white60 : (isDark ? const Color(0xFF8B949E) : Colors.grey[600]),
          ),
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPokemonMode ? Colors.white38 : (isDark ? const Color(0xFF484F58) : Colors.grey),
            )
          : null,
      onTap: onTap,
    );
  }
}
