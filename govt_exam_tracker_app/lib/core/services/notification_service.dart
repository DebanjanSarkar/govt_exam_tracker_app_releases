import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/reminder_model.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(void Function(NotificationResponse) onNotificationTap) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  // ===========================================================================
  // ADVANCED CUSTOM ALARMS & REMINDERS (V7)
  // ===========================================================================

  static Future<void> scheduleCustomReminder(ReminderModel reminder) async {
    await cancelCustomReminder(reminder.id);
    if (!reminder.isActive) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'custom_study_reminders', 'Study & Task Reminders',
      channelDescription: 'Custom alarms set by you for mock tests, studying, and checking results',
      importance: Importance.max, priority: Priority.high, color: Colors.purple,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

  // ===========================================================================
  // DEFAULT EXAM LIFECYCLE ALARMS (Restored!)
  // ===========================================================================
  static Future<void> scheduleExamReminders(ExamModel exam) async {
    await cancelExamReminders(exam.id);
    if (!exam.reminderEnabled || exam.status == ApplicationStatus.archived) return;

    const AndroidNotificationDetails defaultDetails = AndroidNotificationDetails(
      'govt_exam_reminders', 'Exam Reminders',
      importance: Importance.max, priority: Priority.high, color: Color(0xFF1E3A8A),
    );
    const NotificationDetails platformDetails = NotificationDetails(android: defaultDetails);

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
          payload: exam.id, // Deep link payload!
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
          payload: exam.id, // Deep link payload!
        );
      }
    }
  }

  static Future<void> cancelExamReminders(String examId) async {
    await _notificationsPlugin.cancel(_generateId(examId, 101));
    await _notificationsPlugin.cancel(_generateId(examId, 102));
  }
}