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

    // 1. Check Final Result (End of Journey)
    final finalState = exam.phaseStates['result'];
    if (finalState == 'failed') return LifecycleBadge('Rejected', AppTheme.dangerColor, Icons.cancel);
    if (finalState == 'missed') return LifecycleBadge('Missed Final Phase', Colors.grey.shade700, Icons.block);
    if (finalState == 'cleared') return LifecycleBadge('Selected!', AppTheme.successColor, Icons.workspace_premium);

    // 2. DYNAMIC JOURNEY BADGE LOGIC (Bottom-Up Evaluation)
    if (exam.status == ApplicationStatus.applied) {

      // Check for missed phases first (If you miss one, the journey ends)
      if (exam.phaseStates['dv'] == 'missed') return LifecycleBadge('Missed DV', Colors.grey.shade700, Icons.block);
      if (exam.phaseStates['interview'] == 'missed') return LifecycleBadge('Missed Interview', Colors.grey.shade700, Icons.block);
      if (exam.phaseStates['skill'] == 'missed') return LifecycleBadge('Missed Skill Test', Colors.grey.shade700, Icons.block);
      if (exam.phaseStates['mains'] == 'missed') return LifecycleBadge('Missed Mains', Colors.grey.shade700, Icons.block);
      if (exam.phaseStates['prelims'] == 'missed') return LifecycleBadge('Missed Prelims', Colors.grey.shade700, Icons.block);

      // Evaluate Document Verification
      if (exam.hasDV) {
        final state = exam.phaseStates['dv'];
        if (state == 'failed') return LifecycleBadge('Failed DV', AppTheme.dangerColor, Icons.cancel);
        if (state == 'cleared') return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'exam_given') return LifecycleBadge('Awaiting DV Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'admit_card') return LifecycleBadge('DV Call Letter Out', AppTheme.warningColor, Icons.contact_mail);
      }

      // Evaluate Interview
      if (exam.hasInterview) {
        final state = exam.phaseStates['interview'];
        if (state == 'failed') return LifecycleBadge('Failed Interview', AppTheme.dangerColor, Icons.cancel);
        if (state == 'cleared') return exam.hasDV ? LifecycleBadge('Awaiting DV', AppTheme.secondaryColor, Icons.folder_shared) : LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'exam_given') return LifecycleBadge('Awaiting Interview Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'admit_card') return LifecycleBadge('Interview Call Letter Out', AppTheme.warningColor, Icons.contact_mail);
      }

      // Evaluate Skill / Physical Test
      if (exam.hasSkillTest) {
        final state = exam.phaseStates['skill'];
        if (state == 'failed') return LifecycleBadge('Failed Skill Test', AppTheme.dangerColor, Icons.cancel);
        if (state == 'cleared') {
          if (exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
          if (exam.hasDV) return LifecycleBadge('Awaiting DV', AppTheme.secondaryColor, Icons.folder_shared);
          return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
        }
        if (state == 'exam_given') return LifecycleBadge('Awaiting Skill Test Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'admit_card') return LifecycleBadge('Skill Test Admit Card Out', AppTheme.warningColor, Icons.contact_mail);
      }

      // Evaluate Mains / CBT-2
      if (exam.hasMains) {
        final state = exam.phaseStates['mains'];
        if (state == 'failed') return LifecycleBadge('Failed Mains', AppTheme.dangerColor, Icons.cancel);
        if (state == 'cleared') {
          if (exam.hasSkillTest) return LifecycleBadge('Awaiting Skill Test', AppTheme.secondaryColor, Icons.keyboard);
          if (exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
          if (exam.hasDV) return LifecycleBadge('Awaiting DV', AppTheme.secondaryColor, Icons.folder_shared);
          return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
        }
        if (state == 'exam_given') return LifecycleBadge('Awaiting Mains Result', AppTheme.resultColor, Icons.hourglass_bottom);
        if (state == 'admit_card') return LifecycleBadge('Mains Admit Card Out', AppTheme.warningColor, Icons.contact_mail);
      }

      // Evaluate Prelims / CBT-1
      final pState = exam.phaseStates['prelims'];
      if (pState == 'failed') return LifecycleBadge('Failed Prelims', AppTheme.dangerColor, Icons.cancel);
      if (pState == 'cleared') {
        if (exam.hasMains) return LifecycleBadge('Awaiting Mains', AppTheme.secondaryColor, Icons.edit_document);
        if (exam.hasSkillTest) return LifecycleBadge('Awaiting Skill Test', AppTheme.secondaryColor, Icons.keyboard);
        if (exam.hasInterview) return LifecycleBadge('Awaiting Interview', AppTheme.secondaryColor, Icons.mic);
        if (exam.hasDV) return LifecycleBadge('Awaiting DV', AppTheme.secondaryColor, Icons.folder_shared);
        return LifecycleBadge('Awaiting Final Result', AppTheme.resultColor, Icons.hourglass_bottom);
      }
      if (pState == 'exam_given') return LifecycleBadge('Awaiting Prelims Result', AppTheme.resultColor, Icons.hourglass_bottom);
      if (pState == 'admit_card') return LifecycleBadge('Prelims Admit Card Out', AppTheme.warningColor, Icons.contact_mail);

      // Fallback 1: If it's pending but we have a Prelims Date
      if (exam.examDate != null) {
        final exDate = DateTime(exam.examDate!.year, exam.examDate!.month, exam.examDate!.day);
        final diff = exDate.difference(today).inDays;

        if (diff > 0) return LifecycleBadge('Prelims in $diff days', AppTheme.secondaryColor, Icons.calendar_today);
        else if (diff == 0) return LifecycleBadge('Prelims Today!', AppTheme.dangerColor, Icons.warning_amber_rounded);
        else return LifecycleBadge('Awaiting Prelims Result', AppTheme.resultColor, Icons.hourglass_empty);
      }

      // Fallback 2: Applied, but no dates known
      if (exam.applicationEndDate != null) {
        final diff = today.difference(DateTime(exam.applicationEndDate!.year, exam.applicationEndDate!.month, exam.applicationEndDate!.day)).inDays;
        if (diff > 0) return LifecycleBadge('Applied • Ended $diff days ago', AppTheme.secondaryColor.withOpacity(0.8), Icons.history);
      }

      return LifecycleBadge('Applied', AppTheme.secondaryColor, Icons.check_circle);
    }

    // Default Statuses (For Open/Closed Applications)
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