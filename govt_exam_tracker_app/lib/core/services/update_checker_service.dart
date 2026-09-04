import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckerService {
  // This is the "Raw" URL of the JSON file you just created on GitHub
  static const String _jsonUrl = 'https://raw.githubusercontent.com/DebanjanSarkar/govt_exam_tracker_app_releases/main/latest_version.json';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get the current app version installed on the phone
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentBuildNumber = int.parse(packageInfo.buildNumber);

      // 2. Fetch the latest version info from GitHub
      final response = await http.get(Uri.parse(_jsonUrl)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int latestBuildNumber = data['build_number'];
        final String latestVersion = data['version'];
        final String updateUrl = data['url'];
        final String releaseNotes = data['release_notes'] ?? 'Bug fixes and performance improvements.';

        // 3. Compare build numbers. If GitHub has a higher number, show the popup!
        if (latestBuildNumber > currentBuildNumber) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, releaseNotes, updateUrl);
          }
        }
      }
    } catch (e) {
      // Fail silently. If the user has no internet, we don't want to show an error popup.
      debugPrint('Update check failed: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, String latestVersion, String releaseNotes, String url) {
    showDialog(
        context: context,
        barrierDismissible: false, // Forces the user to look at it
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.system_update_alt, color: Colors.purple),
                SizedBox(width: 8),
                Text('Update Available!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version $latestVersion is ready to download.', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('What\'s new:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(releaseNotes, style: const TextStyle(fontSize: 14)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
              FilledButton(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Download Now'),
              ),
            ],
          );
        }
    );
  }
}