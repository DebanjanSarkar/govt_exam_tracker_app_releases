import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../../data/models/exam_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Safe Initialization (No Popups during splash screen)
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // Use local device timezone
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Indian Standard Time

    const AndroidInitializationSettings androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  // 2. The Permission Request (Called safely AFTER the app draws)
  static Future<void> requestPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Generates a unique integer ID from a string ID so we can cancel/overwrite specific alarms
  static int _generateId(String stringId, int type) {
    return (stringId.hashCode + type).abs() % 2147483647; // Max 32-bit int
  }

  static Future<void> scheduleExamReminders(ExamModel exam) async {
    // 1. Cancel existing notifications for this exam first (in case dates were updated)
    await cancelExamReminders(exam.id);

    if (!exam.reminderEnabled || exam.status == ApplicationStatus.archived) return;

    final now = DateTime.now();

    // Application Deadline Reminder (2 Days Before)
    if (exam.applicationEndDate != null && exam.status == ApplicationStatus.notApplied) {
      final deadline = exam.applicationEndDate!;
      final reminderTime = DateTime(deadline.year, deadline.month, deadline.day, 10, 0); // 10:00 AM
      final scheduledTime = reminderTime.subtract(const Duration(days: 2));

      if (scheduledTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateId(exam.id, 1),
          title: 'Application Closing Soon!',
          body: '${exam.examName} deadline is in 2 days. Apply now!',
          scheduledTime: scheduledTime,
        );
      }
    }

    // Prelims Exam Reminder (2 Days Before)
    if (exam.examDate != null &&
        (exam.status == ApplicationStatus.applied || exam.status == ApplicationStatus.admitCardOut)) {
      final examDate = exam.examDate!;
      final reminderTime = DateTime(examDate.year, examDate.month, examDate.day, 18, 0); // 6:00 PM
      final scheduledTime = reminderTime.subtract(const Duration(days: 2));

      if (scheduledTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateId(exam.id, 2),
          title: 'Upcoming Exam!',
          body: 'Your exam for ${exam.examName} is in 2 days. Keep revising!',
          scheduledTime: scheduledTime,
        );
      }
    }
  }

  static Future<void> cancelExamReminders(String examId) async {
    await _notificationsPlugin.cancel(_generateId(examId, 1));
    await _notificationsPlugin.cancel(_generateId(examId, 2));
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'govt_exam_reminders',
      'Exam Reminders',
      channelDescription: 'Notifications for upcoming exam deadlines and dates',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF1E3A8A), // App Theme Primary Color
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}