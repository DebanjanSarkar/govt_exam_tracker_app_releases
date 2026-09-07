import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../data/models/exam_model.dart';
import '../../data/models/reminder_model.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(void Function(NotificationResponse) onNotificationTap) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('ic_notification');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  }

  static Future<void> requestPermission() async {
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  static int _generateId(String stringId, int variant) {
    return (stringId.hashCode + variant).abs() % 2147483647;
  }

  static Future<void> scheduleCustomReminder(ReminderModel reminder) async {
    await cancelCustomReminder(reminder.id);
    if (!reminder.isActive) return;

    final isHighPriority = reminder.isHighPriority;

    final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 1500]);
    final Int32List flags = isHighPriority ? Int32List.fromList([4]) : Int32List.fromList([0]); // 4 is FLAG_INSISTENT (Loops sound)

    // THE DYNAMIC HARDWARE CONFIGURATION
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isHighPriority ? 'govt_exam_alarms_high_v2' : 'govt_exam_alarms_norm_v2',
      isHighPriority ? 'High Priority Alarms' : 'Standard Reminders',
      channelDescription: isHighPriority ? 'Wakes screen and rings continuously.' : 'Standard notifications.',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.purple,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      additionalFlags: flags,
      sound: const RawResourceAndroidNotificationSound('exam_alarm'),

      // CRITICAL FOR DOZE BYPASS:
      // If high priority, route sound through Alarm stream and force screen wake!
      category: isHighPriority ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      audioAttributesUsage: isHighPriority ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      fullScreenIntent: isHighPriority,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // CRITICAL FOR HARDWARE SCHEDULING:
    // alarmClock mode uses zero RAM and forces the OS to wake up at the exact millisecond!
    final scheduleMode = isHighPriority ? AndroidScheduleMode.alarmClock : AndroidScheduleMode.exactAllowWhileIdle;

    final title = reminder.examName;
    final body = reminder.description != null && reminder.description!.isNotEmpty
        ? '${reminder.title}\n${reminder.description}'
        : reminder.title;

    DateTime? absoluteEndDate = reminder.endDate;
    if (reminder.endType == 'phase' && reminder.endPhase != null) {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(DatabaseHelper.tableExams, where: 'id = ?', whereArgs: [reminder.examId]);
      if (maps.isNotEmpty) {
        final exam = ExamModel.fromMap(maps.first);
        switch (reminder.endPhase) {
          case 'prelims': absoluteEndDate = exam.examDate; break;
          case 'mains': absoluteEndDate = exam.mainsExamDate; break;
          case 'skill': absoluteEndDate = exam.skillTestDate; break;
          case 'interview': absoluteEndDate = exam.interviewDate; break;
          case 'dv': absoluteEndDate = exam.dvDate; break;
          case 'result': absoluteEndDate = exam.resultDate; break;
        }
      }
    }

    final now = DateTime.now();

    if (reminder.repeatType == 'none') {
      if (reminder.time.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          _generateId(reminder.id, 0), title, body,
          tz.TZDateTime.from(reminder.time, tz.local), platformDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: reminder.examId,
        );
      }
    }
    else if (reminder.repeatType == 'custom') {
      List<DateTime> upcomingDates = [];
      DateTime pointer = reminder.time.isBefore(now)
          ? DateTime(now.year, now.month, now.day, reminder.time.hour, reminder.time.minute)
          : reminder.time;

      if (pointer.isBefore(now)) pointer = pointer.add(const Duration(days: 1));

      while (upcomingDates.length < 15) {
        if (absoluteEndDate != null && pointer.isAfter(absoluteEndDate)) break;

        if (reminder.frequency == 'day') {
          upcomingDates.add(pointer);
          pointer = pointer.add(Duration(days: reminder.interval));
        }
        else if (reminder.frequency == 'week') {
          if (reminder.weekdays.contains(pointer.weekday)) {
            upcomingDates.add(pointer);
          }
          pointer = pointer.add(const Duration(days: 1));
          if (pointer.weekday == 1 && reminder.interval > 1) {
            pointer = pointer.add(Duration(days: 7 * (reminder.interval - 1)));
          }
        }
        else if (reminder.frequency == 'month') {
          upcomingDates.add(pointer);
          pointer = DateTime(pointer.year, pointer.month + reminder.interval, pointer.day, pointer.hour, pointer.minute);
        }
      }

      for (int i = 0; i < upcomingDates.length; i++) {
        await _notificationsPlugin.zonedSchedule(
          _generateId(reminder.id, i), title, body,
          tz.TZDateTime.from(upcomingDates[i], tz.local), platformDetails,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: reminder.examId,
        );
      }
    }
  }

  static Future<void> cancelCustomReminder(String reminderId) async {
    for (int i = 0; i < 20; i++) {
      await _notificationsPlugin.cancel(_generateId(reminderId, i));
    }
  }

  static Future<void> scheduleExamReminders(ExamModel exam) async {
    await cancelExamReminders(exam.id);
    if (!exam.reminderEnabled || exam.status == ApplicationStatus.archived) return;

    final Int64List vibrationPattern = Int64List.fromList([0, 500, 200, 500]);
    final AndroidNotificationDetails defaultDetails = AndroidNotificationDetails(
      'govt_exam_reminders_v2', 'Exam Deadlines',
      importance: Importance.max, priority: Priority.high, color: const Color(0xFF1E3A8A),
      enableVibration: true, vibrationPattern: vibrationPattern,
      sound: const RawResourceAndroidNotificationSound('exam_alarm'),
    );
    final NotificationDetails platformDetails = NotificationDetails(android: defaultDetails);

    final now = DateTime.now();

    if (exam.applicationEndDate != null && exam.status == ApplicationStatus.notApplied) {
      final deadline = exam.applicationEndDate!;
      final scheduledTime = DateTime(deadline.year, deadline.month, deadline.day, 10, 0).subtract(const Duration(days: 2));
      if (scheduledTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          _generateId(exam.id, 101), 'Application Closing Soon!', '${exam.examName} deadline is in 2 days. Apply now!',
          tz.TZDateTime.from(scheduledTime, tz.local), platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: exam.id,
        );
      }
    }

    if (exam.examDate != null && (exam.status == ApplicationStatus.applied || exam.status == ApplicationStatus.admitCardOut)) {
      final scheduledTime = DateTime(exam.examDate!.year, exam.examDate!.month, exam.examDate!.day, 18, 0).subtract(const Duration(days: 2));
      if (scheduledTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          _generateId(exam.id, 102), 'Upcoming Exam!', 'Your exam for ${exam.examName} is in 2 days. Keep revising!',
          tz.TZDateTime.from(scheduledTime, tz.local), platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: exam.id,
        );
      }
    }
  }

  static Future<void> cancelExamReminders(String examId) async {
    await _notificationsPlugin.cancel(_generateId(examId, 101));
    await _notificationsPlugin.cancel(_generateId(examId, 102));
  }
}