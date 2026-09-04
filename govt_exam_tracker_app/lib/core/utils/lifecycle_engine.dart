import 'package:flutter/material.dart';
import '../../data/models/exam_model.dart';
import '../theme/app_theme.dart';

class LifecycleBadge {
  final String text;
  final Color color;
  final IconData icon;

  LifecycleBadge(this.text, this.color, this.icon);
}

class LifecycleEngine {
  static LifecycleBadge getBadge(ExamModel exam) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (exam.status) {
      case ApplicationStatus.notApplied:
        if (exam.applicationEndDate != null) {
          final endDate = DateTime(exam.applicationEndDate!.year, exam.applicationEndDate!.month, exam.applicationEndDate!.day);
          final diff = endDate.difference(today).inDays;

          if (diff >= 0) {
            return LifecycleBadge('Open • $diff days left', diff <= 3 ? AppTheme.dangerColor : AppTheme.successColor, Icons.timer_outlined);
          } else {
            return LifecycleBadge('Closed • ${diff.abs()} days ago', Colors.grey.shade600, Icons.timer_off_outlined);
          }
        }
        return LifecycleBadge('Not Applied', Colors.grey.shade600, Icons.info_outline);

      case ApplicationStatus.applied:
      // SCENARIO 1: Exam Date is KNOWN
        if (exam.examDate != null) {
          final exDate = DateTime(exam.examDate!.year, exam.examDate!.month, exam.examDate!.day);
          final diff = exDate.difference(today).inDays;

          if (diff > 0) return LifecycleBadge('Exam in $diff days', AppTheme.secondaryColor, Icons.calendar_today);
          else if (diff == 0) return LifecycleBadge('Exam is Today!', AppTheme.dangerColor, Icons.warning_amber_rounded);
          else return LifecycleBadge('Exam Passed', AppTheme.primaryColor, Icons.check_circle_outline);
        }

        // SCENARIO 2: Exam Date is UNKNOWN (Point 2 implementation)
        if (exam.applicationEndDate != null) {
          final endDate = DateTime(exam.applicationEndDate!.year, exam.applicationEndDate!.month, exam.applicationEndDate!.day);
          final diff = today.difference(endDate).inDays;

          if (diff > 0) {
            return LifecycleBadge('Applied • Ended $diff days ago', AppTheme.secondaryColor.withOpacity(0.8), Icons.history);
          }
        }
        return LifecycleBadge('Applied', AppTheme.secondaryColor, Icons.check_circle);

      case ApplicationStatus.admitCardOut:
        return LifecycleBadge('Admit Card Out', AppTheme.warningColor, Icons.contact_mail);

      case ApplicationStatus.examGiven:
        return LifecycleBadge('Awaiting Result', AppTheme.resultColor, Icons.hourglass_bottom);

      case ApplicationStatus.resultOut:
        return LifecycleBadge('Result Declared', AppTheme.successColor, Icons.emoji_events);

      case ApplicationStatus.archived:
        return LifecycleBadge('Archived', Colors.grey, Icons.archive);
    }
  }
}