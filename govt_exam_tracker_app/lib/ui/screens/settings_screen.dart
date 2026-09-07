import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_cooldown_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart'; // NEW IMPORT

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _cerebrasCtrl = TextEditingController();
  final TextEditingController _groqCtrl = TextEditingController();

  bool _isCerebrasLocked = true;
  bool _isGroqLocked = true;
  String _activeProvider = 'groq';

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _cerebrasCtrl.text = prefs.getString(AppConstants.prefsGeminiApiKey) ?? '';
    _groqCtrl.text = prefs.getString(AppConstants.prefsGroqApiKey) ?? '';
    _activeProvider = prefs.getString(AppConstants.prefsActiveAiProvider) ?? 'groq';
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.prefsGeminiApiKey, _cerebrasCtrl.text.trim());
    await prefs.setString(AppConstants.prefsGroqApiKey, _groqCtrl.text.trim());
    await prefs.setString(AppConstants.prefsActiveAiProvider, _activeProvider);

    setState(() {
      _isCerebrasLocked = true;
      _isGroqLocked = true;
    });

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved Successfully!'), backgroundColor: Colors.green));
  }

  Future<bool> _confirmEdit(String providerName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit API Key?'),
        content: Text('Are you sure you want to edit your $providerName API Key? Incorrect changes will break the AI features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Edit')),
        ],
      ),
    ) ?? false;
  }

  Widget _buildKeyField(String label, TextEditingController controller, bool isLocked, VoidCallback onUnlock) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: isLocked,
            obscureText: isLocked,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key),
              filled: isLocked,
              // Adapts perfectly to light/dark mode
              fillColor: isLocked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isLocked)
          IconButton.filledTonal(onPressed: onUnlock, icon: const Icon(Icons.edit), tooltip: 'Edit Key')
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ==========================================
          // APPEARANCE & THEME SETTINGS
          // ==========================================
          const Row(
            children: [
              Icon(Icons.palette, color: Colors.blue),
              SizedBox(width: 8),
              Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Match System Default', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Automatically switches with your phone.'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  activeColor: Colors.blue,
                  onChanged: (val) => ref.read(themeProvider.notifier).setTheme(val!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  activeColor: Colors.blue,
                  onChanged: (val) => ref.read(themeProvider.notifier).setTheme(val!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  activeColor: Colors.blue,
                  onChanged: (val) => ref.read(themeProvider.notifier).setTheme(val!),
                ),
              ],
            ),
          ),

          const Divider(height: 48),

          // ==========================================
          // AI CONFIGURATION SETTINGS
          // ==========================================
          const Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.purple),
              SizedBox(width: 8),
              Text('AI Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Provide your own free API keys to enable unlimited AI features without server fees.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => launchUrl(Uri.parse('https://cloud.cerebras.ai/'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Get Cerebras Key', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => launchUrl(Uri.parse('https://console.groq.com/keys'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Get Groq Key', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text('Engine for Current Use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Use Groq', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Lightning Fast • Strict Daily Limit'),
                  value: 'groq',
                  groupValue: _activeProvider,
                  activeColor: Colors.purple,
                  onChanged: (val) => setState(() => _activeProvider = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Use Cerebras (Llama 3.1)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('1 Million Tokens Free/Day • Very Stable'),
                  value: 'gemini',
                  groupValue: _activeProvider,
                  activeColor: Colors.purple,
                  onChanged: (val) => setState(() => _activeProvider = val!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildKeyField(
              'Cerebras API Key',
              _cerebrasCtrl,
              _isCerebrasLocked,
                  () async { if (await _confirmEdit('Cerebras')) setState(() => _isCerebrasLocked = false); }
          ),

          const SizedBox(height: 16),
          _buildKeyField(
              'Groq API Key',
              _groqCtrl,
              _isGroqLocked,
                  () async { if (await _confirmEdit('Groq')) setState(() => _isGroqLocked = false); }
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saveSettings,
              child: const Text('Save AI Configuration', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}