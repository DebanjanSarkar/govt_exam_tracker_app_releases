import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'core/services/notification_service.dart';
import 'providers/ai_cooldown_provider.dart';
import 'providers/theme_provider.dart'; // NEW IMPORT

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      await NotificationService.initialize();
      _prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.requestPermission();
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString() + "\n\n" + stackTrace.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Respect system theme during crash
        home: Scaffold(
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

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Respect system theme during loading
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Warming up engines...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs),
      ],
      child: const GovtExamTrackerApp(),
    );
  }
}

// CHANGED TO CONSUMER WIDGET to listen to Theme Provider
class GovtExamTrackerApp extends ConsumerWidget {
  const GovtExamTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Government Exams Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // DYNAMICALLY RESPONDS TO THE PROVIDER
      home: const DashboardScreen(),
    );
  }
}