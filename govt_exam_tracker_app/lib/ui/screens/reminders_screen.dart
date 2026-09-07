import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/reminder_provider.dart';
import '../../data/models/reminder_model.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersState = ref.watch(reminderListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Master Alarm Hub', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: remindersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No active alarms.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Go to any Exam Details page to set up\nstudy routines and result checks.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Sort reminders: Active first, then by creation date
          final sortedReminders = List<ReminderModel>.from(reminders);
          sortedReminders.sort((a, b) {
            if (a.isActive && !b.isActive) return -1;
            if (!a.isActive && b.isActive) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedReminders.length,
            itemBuilder: (context, index) {
              final r = sortedReminders[index];
              String repeatText = r.repeatType == 'daily' ? 'Daily' : r.repeatType == 'none' ? 'Once' : 'Weekly';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: r.isActive ? 2 : 0,
                color: r.isActive ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: r.isActive ? Colors.purple.withOpacity(0.3) : Colors.transparent),
                    borderRadius: BorderRadius.circular(16)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Exam Name
                      Row(
                        children: [
                          Icon(Icons.assignment, size: 16, color: r.isActive ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.examName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: r.isActive ? Colors.blue.shade700 : Colors.grey
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Alarm?'),
                                  content: const Text('This will permanently remove this reminder.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(reminderListProvider.notifier).deleteReminder(r.id);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Body: Alarm Details & Toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    r.title,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        decoration: r.isActive ? null : TextDecoration.lineThrough,
                                        color: r.isActive ? theme.colorScheme.onSurface : Colors.grey
                                    )
                                ),
                                if (r.description != null && r.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                                    child: Text(r.description!, style: TextStyle(color: r.isActive ? Colors.grey.shade700 : Colors.grey)),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: r.isActive ? Colors.purple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: r.isActive ? Colors.purple : Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                          '${DateFormat.jm().format(r.time)} • $repeatText',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: r.isActive ? Colors.purple : Colors.grey)
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          Switch(
                            value: r.isActive,
                            activeColor: Colors.purple,
                            onChanged: (val) {
                              ref.read(reminderListProvider.notifier).toggleReminderState(r);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}