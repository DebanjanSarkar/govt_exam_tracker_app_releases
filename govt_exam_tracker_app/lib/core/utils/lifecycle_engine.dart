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

    // Check if the user marked the final result as failed or selected
    final finalState = exam.phaseStates['result'];
    if (finalState == 'failed') return LifecycleBadge('Rejected', AppTheme.dangerColor, Icons.cancel);
    if (finalState == 'cleared') return LifecycleBadge('Selected!', AppTheme.successColor, Icons.workspace_premium);

    // DYNAMIC JOURNEY BADGE LOGIC (Reads the Timeline phases)
    if (exam.status == ApplicationStatus.applied) {

      if (exam.phaseStates['interview'] == 'cleared') return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
      if (exam.phaseStates['interview'] == 'failed') return LifecycleBadge('Failed Interview', AppTheme.dangerColor, Icons.cancel);

      if (exam.phaseStates['skill'] == 'cleared' && exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
      if (exam.phaseStates['skill'] == 'failed') return LifecycleBadge('Failed Skill Test', AppTheme.dangerColor, Icons.cancel);

      if (exam.phaseStates['mains'] == 'cleared') {
        if (exam.hasSkillTest) return LifecycleBadge('Awaiting Skill Test', AppTheme.secondaryColor, Icons.keyboard);
        if (exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
        return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
      }
      if (exam.phaseStates['mains'] == 'failed') return LifecycleBadge('Failed Mains', AppTheme.dangerColor, Icons.cancel);

      if (exam.phaseStates['prelims'] == 'cleared') {
        if (exam.hasMains) return LifecycleBadge('Awaiting Mains', AppTheme.secondaryColor, Icons.edit_document);
        if (exam.hasSkillTest) return LifecycleBadge('Awaiting Skill Test', AppTheme.secondaryColor, Icons.keyboard);
        if (exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
        return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
      }
      if (exam.phaseStates['prelims'] == 'failed') return LifecycleBadge('Failed Prelims', AppTheme.dangerColor, Icons.cancel);

      // If no phases are explicitly cleared, fallback to Date Math
      if (exam.examDate != null) {
        final exDate = DateTime(exam.examDate!.year, exam.examDate!.month, exam.examDate!.day);
        final diff = exDate.difference(today).inDays;

        if (diff > 0) return LifecycleBadge('Prelims in $diff days', AppTheme.secondaryColor, Icons.calendar_today);
        else if (diff == 0) return LifecycleBadge('Prelims Today!', AppTheme.dangerColor, Icons.warning_amber_rounded);
        else return LifecycleBadge('Awaiting Prelims Result', AppTheme.resultColor, Icons.hourglass_empty);
      }

      // Fallback for Applied exams with no dates
      if (exam.applicationEndDate != null) {
        final diff = today.difference(DateTime(exam.applicationEndDate!.year, exam.applicationEndDate!.month, exam.applicationEndDate!.day)).inDays;
        if (diff > 0) return LifecycleBadge('Applied • Ended $diff days ago', AppTheme.secondaryColor.withOpacity(0.8), Icons.history);
      }
      return LifecycleBadge('Applied', AppTheme.secondaryColor, Icons.check_circle);
    }

    // Standard Application Statuses
    switch (exam.status) {
      case ApplicationStatus.notApplied:
        if (exam.applicationEndDate != null) {
          final diff = DateTime(exam.applicationEndDate!.year, exam.applicationEndDate!.month, exam.applicationEndDate!.day).difference(today).inDays;
          if (diff >= 0) return LifecycleBadge('Open • $diff days left', diff <= 3 ? AppTheme.dangerColor : AppTheme.successColor, Icons.timer_outlined);
          else return LifecycleBadge('Closed • ${diff.abs()} days ago', Colors.grey.shade600, Icons.timer_off_outlined);
        }
        return LifecycleBadge('Not Applied', Colors.grey.shade600, Icons.info_outline);
      case ApplicationStatus.admitCardOut: return LifecycleBadge('Admit Card Out', AppTheme.warningColor, Icons.contact_mail);
      case ApplicationStatus.examGiven: return LifecycleBadge('Awaiting Result', AppTheme.resultColor, Icons.hourglass_bottom);
      case ApplicationStatus.resultOut: return LifecycleBadge('Result Declared', AppTheme.successColor, Icons.emoji_events);
      case ApplicationStatus.archived: return LifecycleBadge('Archived', Colors.grey, Icons.archive);
      default: return LifecycleBadge('Unknown', Colors.grey, Icons.help_outline);
    }
  }
}