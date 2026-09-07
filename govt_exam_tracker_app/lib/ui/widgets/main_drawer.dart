import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../providers/sync_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/export_screen.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  Future<void> _fireTestNotification() async {
    final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Used for testing the notification engine',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1E3A8A),
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      0,
      'Engine is Active! 🚀',
      'If you see this, your exam reminders will work perfectly.',
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: theme.colorScheme.error));
      }
      if (next.lastSyncMessage != null && next.lastSyncMessage != previous?.lastSyncMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.lastSyncMessage!), backgroundColor: theme.colorScheme.primary));
      }
    });

    return Drawer(
      // SAFE AREA prevents the branding from hiding under Android's bottom navigation bar
      child: SafeArea(
        top: false, // The UserAccountsDrawerHeader handles its own top padding
        child: Column(
          children: [
            // 1. SCROLLABLE MENU ITEMS
            // Using Expanded + ListView prevents the overflow error entirely!
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: theme.colorScheme.primary),
                    accountName: Text(syncState.account?.displayName ?? 'Not logged in', style: const TextStyle(fontWeight: FontWeight.bold)),
                    accountEmail: Text(syncState.account?.email ?? 'Sync data across devices securely'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: syncState.account?.photoUrl != null ? NetworkImage(syncState.account!.photoUrl!) : null,
                      child: syncState.account?.photoUrl == null ? Icon(Icons.person, size: 40, color: theme.colorScheme.primary) : null,
                    ),
                  ),

                  if (syncState.account == null) ...[
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Login with Google'),
                      subtitle: const Text('Enable Drive Sync'),
                      onTap: () => ref.read(syncProvider.notifier).login(),
                    ),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.cloud_upload),
                      title: const Text('Backup to Drive'),
                      subtitle: const Text('Save your local data'),
                      trailing: syncState.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                      onTap: syncState.isLoading ? null : () => ref.read(syncProvider.notifier).pushToDrive(),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_download),
                      title: const Text('Sync from Drive'),
                      subtitle: const Text('Pull latest data'),
                      trailing: syncState.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                      onTap: syncState.isLoading ? null : () => ref.read(syncProvider.notifier).pullFromDrive(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () => ref.read(syncProvider.notifier).logout(),
                    ),
                  ],

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.table_view, color: Colors.green),
                    title: const Text('Export to Excel'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen()));
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.notifications_active, color: Colors.amber),
                    title: const Text('Test Notification Engine'),
                    onTap: () {
                      Navigator.pop(context);
                      _fireTestNotification();
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.purple),
                    title: const Text('AI and Theme Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            // 2. FIXED BRANDING SECTION AT THE BOTTOM
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0, left: 16.0, right: 16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Wraps content tightly
                children: [
                  Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Crafted with dedication by',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Text(
                    'Debanjan Sarkar',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'To empower fellow aspirants on their journey to success.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}