import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'core/services/notification_service.dart';
import 'providers/ai_cooldown_provider.dart';

void main() {
  // 1. Ensure bindings are ready immediately
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Run the App INSTANTLY to clear the native black Splash Screen.
  // All heavy "await" initializations are moved inside the widget.
  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMsg;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Safely initialize Background Notifications
      await NotificationService.initialize();

      // Initialize Persistent Storage
      _prefs = await SharedPreferences.getInstance();

      // If everything succeeds, update state to show the main app
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Request notification permissions safely AFTER the UI has rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.requestPermission();
        });
      }
    } catch (e, stackTrace) {
      // If ANYTHING fails, catch it and show it on screen instead of freezing!
      if (mounted) {
        setState(() {
          _errorMsg = e.toString() + "\n\n" + stackTrace.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SCENARIO A: An error occurred during startup
    if (_errorMsg != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text('Startup Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // SCENARIO B: Still loading dependencies (Shows instead of a black screen)
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                SizedBox(height: 16),
                Text('Warming up engines...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    // SCENARIO C: Success! Load the Riverpod scope and App
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
      ],
      child: const GovtExamTrackerApp(),
    );
  }
}

class GovtExamTrackerApp extends StatelessWidget {
  const GovtExamTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Government Exams Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}