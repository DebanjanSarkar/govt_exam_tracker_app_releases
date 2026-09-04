import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_cooldown_provider.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _keyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _keyCtrl.text = prefs.getString(AppConstants.prefsApiKey) ?? '';
  }

  void _saveKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.prefsApiKey, _keyCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key Saved successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.smart_toy, size: 64, color: Colors.purple),
          const SizedBox(height: 16),
          const Text('Enable AI Auto-Fill', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('To keep this app 100% free and private, you need to provide your own free Groq API Key.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),

          FilledButton.tonalIcon(
            onPressed: () => launchUrl(Uri.parse('https://console.groq.com/keys'), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Get Free API Key here'),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _keyCtrl,
            decoration: const InputDecoration(
              labelText: 'Paste your API Key (gsk_...)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saveKey,
            child: const Text('Save API Key'),
          ),
        ],
      ),
    );
  }
}