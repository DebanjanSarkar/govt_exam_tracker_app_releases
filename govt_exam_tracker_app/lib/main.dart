import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/exam_detail_screen.dart';
import 'core/services/notification_service.dart';
import 'providers/exam_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_cooldown_provider.dart'; // Guarantees sharedPreferencesProvider is found

// GLOBAL NAVIGATOR KEY FOR DEEP LINKING
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      // INITIALIZE NOTIFICATIONS AND PASS THE DEEP LINK CALLBACK
      await NotificationService.initialize((notificationResponse) {
        final String? payloadExamId = notificationResponse.payload;
        if (payloadExamId != null && payloadExamId.isNotEmpty) {
          // Force navigate to the Deep Link Handler
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => DeepLinkHandler(examId: payloadExamId)),
          );
        }
      });

      _prefs = await SharedPreferences.getInstance();

      if (mounted) {
        setState(() => _isInitialized = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.requestPermission();
        });
      }
    } catch (e, stackTrace) {
      if (mounted) setState(() => _errorMsg = e.toString() + "\n\n" + stackTrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: ThemeMode.system,
        home: Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16), const Text('Startup Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 14))])))),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: ThemeMode.system,
        home: const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Warming up engines...', style: TextStyle(color: Colors.grey))]))),
      );
    }

    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(_prefs)],
      child: const GovtExamTrackerApp(),
    );
  }
}

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
      themeMode: themeMode,
      navigatorKey: navigatorKey, // ATTACH THE GLOBAL NAVIGATOR HERE!
      home: const DashboardScreen(),
    );
  }
}

// A smart intermediary screen that safely fetches the correct Exam from Riverpod
class DeepLinkHandler extends ConsumerWidget {
  final String examId;
  const DeepLinkHandler({super.key, required this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsState = ref.watch(examListProvider);

    return examsState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Failed to load exam details.'))),
      data: (exams) {
        final exam = exams.firstWhere((e) => e.id == examId, orElse: () => throw Exception());
        // Instantly replace this loading screen with the actual Exam Details screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ExamDetailScreen(exam: exam)));
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}