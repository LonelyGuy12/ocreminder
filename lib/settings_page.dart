import 'package:flutter/material.dart';
import 'package:lonelyreminder/services/google_auth_service.dart';
import 'package:lonelyreminder/providers/theme_provider.dart';
import 'package:lonelyreminder/services/calendar_service.dart';
import 'package:lonelyreminder/services/cloud_sync_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleAuthService _authService = GoogleAuthService();
  final CloudSyncService _cloudSync = CloudSyncService();
  User? _currentUser;

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    required bool isPokemonMode,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isPokemonMode
                ? color.withOpacity(0.1)
                : (isDark ? const Color(0xFF21262D) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(12),
            border: isPokemonMode
                ? Border.all(color: color.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDestructive
                        ? color
                        : (isPokemonMode
                            ? Colors.white
                            : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E))),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isPokemonMode
                    ? Colors.white38
                    : (isDark ? const Color(0xFF6E7681) : Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required bool isPokemonMode,
    required bool isDark,
    bool showEmoji = false,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isPokemonMode
              ? (value ? const Color(0xFFFF6B35) : Colors.white)
              : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isPokemonMode
                ? Colors.white60
                : (isDark ? const Color(0xFF8B949E) : Colors.grey[600]),
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? activeColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          border: value ? Border.all(color: activeColor, width: 2) : null,
        ),
        child: showEmoji
            ? const Center(child: Text('🐉', style: TextStyle(fontSize: 22)))
            : Icon(icon, color: value ? activeColor : Colors.grey, size: 22),
      ),
      activeColor: activeColor,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = _authService.getCurrentUser();
    if (mounted) setState(() {});
  }

  Future<void> _signInWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        setState(() {
          _currentUser = userCredential.user;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${userCredential.user?.displayName}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() {
      _currentUser = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out successfully')),
    );
  }

  Future<void> _importFromGoogleCalendar() async {
    if (_currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in with Google first')),
      );
      return;
    }

    if (!mounted) return;
    _showImportDialog();
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import Google Calendar Events'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Fetching events from your Google Calendar...',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'This may take a moment if you have many events.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );

    _performImport();
  }

  Future<void> _performImport() async {
    try {
      final accessToken = await _authService.getGoogleCalendarAccessToken();
      if (accessToken == null) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get calendar access token'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final calendarService = CalendarService();
      final importedCount = await calendarService.importToDatabase(accessToken);

      if (!mounted) return;
      Navigator.pop(context);

      if (importedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $importedCount event${importedCount == 1 ? '' : 's'} imported'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new events to import'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPokemonMode = context.watch<ThemeProvider>().isPokemonMode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isPokemonMode ? '⚙️ Trainer Settings ⚙️' : 'Settings'),
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
                      ? [
                          const Color(0xFF0A0E27),
                          const Color(0xFF1A1F3A),
                        ]
                      : [
                          Colors.teal.shade50,
                          Colors.white,
                        ],
                ),
              ),
        child: ListView(
          padding: EdgeInsets.only(
            top: isPokemonMode ? kToolbarHeight + MediaQuery.of(context).padding.top + 16 : 16,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            // Theme Toggle
            Card(
              elevation: isDark ? 8 : 4,
              color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isPokemonMode
                    ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: isPokemonMode
                                  ? const Color(0xFFFF6B35)
                                  : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isPokemonMode
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildThemeOption(
                          title: 'Night Mode',
                          subtitle: 'Deep space theme with neon accents',
                          icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                          activeColor: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B),
                          isPokemonMode: isPokemonMode,
                          isDark: isDark,
                        ),
                        Divider(
                          color: isPokemonMode
                              ? const Color(0xFFFF6B35).withOpacity(0.3)
                              : (isDark ? const Color(0xFF21262D) : Colors.grey.shade200),
                          height: 24,
                        ),
                        _buildThemeOption(
                          title: 'Pokemon Mode 🔥',
                          subtitle: 'Charizard theme for true trainers!',
                          icon: Icons.catching_pokemon,
                          value: themeProvider.isPokemonMode,
                          onChanged: (_) => themeProvider.togglePokemonMode(),
                          activeColor: const Color(0xFFFF6B35),
                          isPokemonMode: isPokemonMode,
                          isDark: isDark,
                          showEmoji: true,
                        ),
                        if (isPokemonMode) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF6B35).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Text('🔥', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('⚡', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('💧', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text('🌿', style: TextStyle(fontSize: 20)),
                                Spacer(),
                                Text(
                                  'Trainer Mode Active!',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Account Section
            Card(
              elevation: isDark ? 8 : 4,
              color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isPokemonMode
                    ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPokemonMode ? Icons.catching_pokemon : Icons.account_circle_outlined,
                          color: isPokemonMode
                              ? const Color(0xFFFF6B35)
                              : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isPokemonMode ? 'Trainer Account' : 'Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isPokemonMode
                                ? Colors.white
                                : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_currentUser != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPokemonMode
                              ? const Color(0xFFFF6B35).withOpacity(0.1)
                              : (isDark ? const Color(0xFF21262D) : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: isPokemonMode
                              ? Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isPokemonMode
                                  ? const Color(0xFFFF6B35)
                                  : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
                              backgroundImage: _currentUser!.photoURL != null
                                  ? NetworkImage(_currentUser!.photoURL!)
                                  : null,
                              child: _currentUser!.photoURL == null
                                  ? Text(
                                      isPokemonMode ? '🔥' : (_currentUser!.displayName?.substring(0, 1).toUpperCase() ?? 'U'),
                                      style: const TextStyle(fontSize: 20, color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUser!.displayName ?? _currentUser!.email ?? 'Trainer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isPokemonMode
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPokemonMode ? '⭐ Pokemon Trainer' : 'Signed In',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isPokemonMode
                                          ? const Color(0xFFFFD54F)
                                          : (isDark ? const Color(0xFF8B949E) : Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.verified,
                              color: isPokemonMode
                                  ? const Color(0xFFFFD54F)
                                  : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsButton(
                        icon: Icons.calendar_month,
                        title: isPokemonMode ? 'Sync Pokédex' : 'Import from Google Calendar',
                        onTap: _importFromGoogleCalendar,
                        color: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B),
                        isPokemonMode: isPokemonMode,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildSettingsButton(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        onTap: _signOut,
                        color: const Color(0xFFE53935),
                        isPokemonMode: isPokemonMode,
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ] else ...[
                      _buildSettingsButton(
                        icon: Icons.login,
                        title: isPokemonMode ? 'Join as Trainer' : 'Sign in with Google',
                        onTap: _signInWithGoogle,
                        color: isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B),
                        isPokemonMode: isPokemonMode,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Card(
              elevation: isDark ? 8 : 4,
              color: isPokemonMode ? Colors.black.withOpacity(0.8) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isPokemonMode
                    ? const BorderSide(color: Color(0xFFFF6B35), width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isPokemonMode
                              ? const Color(0xFFFF6B35)
                              : (isDark ? const Color(0xFF7C4DFF) : const Color(0xFF00897B)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isPokemonMode
                                ? Colors.white
                                : (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1A1A2E)),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsButton(
                      icon: Icons.info_outline,
                      title: isPokemonMode ? 'About Pokédex' : 'About App',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: isPokemonMode ? 'Pokemon Reminder' : 'Lonely Reminder',
                          applicationVersion: '1.0.0',
                          applicationIcon: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isPokemonMode
                                    ? [const Color(0xFFFF6B35), const Color(0xFFFFD54F)]
                                    : [const Color(0xFF00897B), const Color(0xFF26A69A)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isPokemonMode ? '🔥' : '📅',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          children: [
                            Text(
                              isPokemonMode
                                  ? 'Catch all your reminders like Pokemon! An intelligent OCR-based event reminder app for true trainers.'
                                  : 'An intelligent OCR-based event reminder app that helps you never miss important events.',
                            ),
                          ],
                        );
                      },
                      color: const Color(0xFF2196F3),
                      isPokemonMode: isPokemonMode,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildSettingsButton(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                      color: const Color(0xFF4CAF50),
                      isPokemonMode: isPokemonMode,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        isPokemonMode ? '⚡ Made with 💛 for Trainers ⚡' : 'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPokemonMode
                              ? const Color(0xFFFFD54F)
                              : (isDark ? const Color(0xFF6E7681) : Colors.grey.shade500),
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
    );
  }
}
