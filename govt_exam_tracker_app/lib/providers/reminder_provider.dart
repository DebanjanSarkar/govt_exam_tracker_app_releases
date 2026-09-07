import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../data/models/reminder_model.dart';
import '../core/services/notification_service.dart';

class ReminderNotifier extends StateNotifier<AsyncValue<List<ReminderModel>>> {
  ReminderNotifier() : super(const AsyncValue.loading()) {
    loadAllReminders();
  }

  Future<void> loadAllReminders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(DatabaseHelper.tableReminders, orderBy: 'created_at DESC');
      state = AsyncValue.data(maps.map((map) => ReminderModel.fromMap(map)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReminder(ReminderModel reminder) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(DatabaseHelper.tableReminders, reminder.toMap());
    await NotificationService.scheduleCustomReminder(reminder);
    await loadAllReminders();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(DatabaseHelper.tableReminders, reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
    await NotificationService.scheduleCustomReminder(reminder);
    await loadAllReminders();
  }

  Future<void> deleteReminder(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(DatabaseHelper.tableReminders, where: 'id = ?', whereArgs: [id]);
    await NotificationService.cancelCustomReminder(id);
    await loadAllReminders();
  }

  Future<void> toggleReminderState(ReminderModel reminder) async {
    final updated = reminder.copyWith(isActive: !reminder.isActive);
    await updateReminder(updated);
    if (updated.isActive) {
      await NotificationService.scheduleCustomReminder(updated);
    } else {
      await NotificationService.cancelCustomReminder(updated.id);
    }
  }

  // NEW: Called by the Google Drive Sync to safely merge remote alarms
  Future<void> bulkSyncInsert(List<ReminderModel> remoteReminders) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final r in remoteReminders) {
      batch.insert(DatabaseHelper.tableReminders, r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      if (r.isActive) {
        await NotificationService.scheduleCustomReminder(r);
      } else {
        await NotificationService.cancelCustomReminder(r.id);
      }
    }
    await batch.commit(noResult: true);
    await loadAllReminders();
  }
}

final reminderListProvider = StateNotifierProvider<ReminderNotifier, AsyncValue<List<ReminderModel>>>((ref) {
  return ReminderNotifier();
});

final examRemindersProvider = Provider.family<List<ReminderModel>, String>((ref, examId) {
  final state = ref.watch(reminderListProvider);
  return state.maybeWhen(
    data: (reminders) => reminders.where((r) => r.examId == examId).toList(),
    orElse: () => [],
  );
});