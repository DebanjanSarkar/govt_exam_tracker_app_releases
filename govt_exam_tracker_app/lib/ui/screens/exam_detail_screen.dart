import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/exam_model.dart';
import '../../core/utils/lifecycle_engine.dart';
import '../../providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ai_cooldown_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/live_update_service.dart';
import 'exam_form_screen.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final ExamModel exam;
  const ExamDetailScreen({super.key, required this.exam});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  bool _obscurePassword = true;

  String _formatDate(DateTime? date) => date == null ? 'Date TBA' : DateFormat('dd MMM yyyy').format(date);

  Future<void> _launchUrl(String urlString) async {
    if (!await launchUrl(Uri.parse(urlString), mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _deleteExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: const Text('This will move the exam to the trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ref.read(examListProvider.notifier).deleteExam(widget.exam.id);
      Navigator.pop(context);
    }
  }

  void _updatePhaseState(ExamModel currentExam, String phaseKey, String newState) {
    final updatedPhases = Map<String, String>.from(currentExam.phaseStates);
    updatedPhases[phaseKey] = newState;
    ref.read(examListProvider.notifier).updateExam(currentExam.copyWith(phaseStates: updatedPhases));
  }

  void _checkLiveStatusAi(ExamModel exam, String phaseTitle) async {
    final cooldownLeft = ref.read(aiCooldownProvider);
    if (cooldownLeft > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI is cooling down. Please wait $cooldownLeft seconds.'), backgroundColor: Colors.orange));
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final userKey = prefs.getString(AppConstants.prefsApiKey);
    if (userKey == null || userKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your Groq API Key in settings first!'), backgroundColor: Colors.red));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: Card(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Searching the web...')])))));

    final result = await LiveUpdateService.getLiveStatus(exam.examName, phaseTitle, userKey);

    ref.read(aiCooldownProvider.notifier).startGlobalCooldown();

    if (mounted) {
      Navigator.pop(context);
      showDialog(context: context, builder: (c) => AlertDialog(
        title: Row(children: [const Icon(Icons.auto_awesome, color: Colors.purple), const SizedBox(width: 8), Expanded(child: Text('Live Update: $phaseTitle'))]),
        content: Text(result, style: const TextStyle(fontSize: 15, height: 1.4)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ));
    }
  }

  Widget _buildTimelineNode(ExamModel currentExam, {required String title, required DateTime? date, required String phaseKey, required bool isLast, required bool isDisabled, required bool isActiveForAi}) {
    final theme = Theme.of(context);
    final String currentState = currentExam.phaseStates[phaseKey] ?? 'pending';

    Color nodeColor = Colors.grey.shade400;
    IconData nodeIcon = Icons.radio_button_unchecked;

    // DYNAMIC COLOR AND ICON LOGIC
    if (currentState == 'cleared') {
      nodeColor = AppTheme.successColor; nodeIcon = Icons.check_circle;
    } else if (currentState == 'failed') {
      nodeColor = AppTheme.dangerColor; nodeIcon = Icons.cancel;
    } else if (currentState == 'missed') {
      nodeColor = Colors.grey.shade700; nodeIcon = Icons.block;
    } else if (currentState == 'exam_given') {
      nodeColor = AppTheme.resultColor; nodeIcon = Icons.assignment_turned_in;
    } else if (currentState == 'admit_card') {
      nodeColor = AppTheme.warningColor; nodeIcon = Icons.downloading;
    }

    final double opacity = isDisabled ? 0.4 : 1.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(children: [Icon(nodeIcon, color: isDisabled ? Colors.grey : nodeColor, size: 24), if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300))]),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Opacity(
                opacity: opacity,
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(_formatDate(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13))])),
                            DropdownButton<String>(
                              value: currentState,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: TextStyle(color: isDisabled ? Colors.grey : nodeColor, fontWeight: FontWeight.bold, fontSize: 13),
                              onChanged: isDisabled ? null : (val) { if (val != null) _updatePhaseState(currentExam, phaseKey, val); },
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'admit_card', child: Text('Admit Card Out')),
                                DropdownMenuItem(value: 'exam_given', child: Text('Exam Given / Attended')),
                                DropdownMenuItem(value: 'cleared', child: Text('Cleared / Passed')),
                                DropdownMenuItem(value: 'failed', child: Text('Failed')),
                                DropdownMenuItem(value: 'missed', child: Text('Missed / Not Attended')),
                              ],
                            ),
                          ],
                        ),
                        if (isActiveForAi && !isDisabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: FilledButton.tonalIcon(
                              onPressed: () => _checkLiveStatusAi(currentExam, title),
                              icon: const Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                              label: const Text('Check Current Status', style: TextStyle(color: Colors.purple, fontSize: 12)),
                              style: FilledButton.styleFrom(backgroundColor: Colors.purple.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 12), visualDensity: VisualDensity.compact),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicStepper(ExamModel currentExam) {
    List<Map<String, dynamic>> stages = [
      {'key': 'prelims', 'title': 'Prelims / CBT-1', 'date': currentExam.examDate}
    ];
    if (currentExam.hasMains) stages.add({'key': 'mains', 'title': 'Mains / CBT-2', 'date': currentExam.mainsExamDate});
    if (currentExam.hasSkillTest) stages.add({'key': 'skill', 'title': 'Skill / Physical Test', 'date': currentExam.skillTestDate});
    if (currentExam.hasInterview) stages.add({'key': 'interview', 'title': 'Interview', 'date': currentExam.interviewDate});
    if (currentExam.hasDV) stages.add({'key': 'dv', 'title': 'Document Verification', 'date': currentExam.dvDate});
    stages.add({'key': 'result', 'title': 'Final Result', 'date': currentExam.resultDate});

    List<Widget> nodes = [];
    bool isJourneyEnded = false;
    bool foundActive = false;

    for (int i = 0; i < stages.length; i++) {
      final stage = stages[i];
      final isLast = i == stages.length - 1;
      final currentState = currentExam.phaseStates[stage['key']] ?? 'pending';

      bool isActiveForAi = false;
      // AI button is active if it's the current frontier stage (including when waiting for result)
      if (!isJourneyEnded && !foundActive && (currentState == 'pending' || currentState == 'admit_card' || currentState == 'exam_given')) {
        isActiveForAi = true;
        foundActive = true;
      }

      nodes.add(_buildTimelineNode(
        currentExam,
        title: stage['title'],
        date: stage['date'],
        phaseKey: stage['key'],
        isLast: isLast,
        isDisabled: isJourneyEnded,
        isActiveForAi: isActiveForAi,
      ));

      if (currentState == 'failed' || currentState == 'missed') {
        isJourneyEnded = true;
      }
    }
    return Column(children: nodes);
  }

  @override
  Widget build(BuildContext context) {
    final examsState = ref.watch(examListProvider);
    final currentExam = examsState.valueOrNull?.firstWhere((e) => e.id == widget.exam.id, orElse: () => widget.exam) ?? widget.exam;

    final theme = Theme.of(context);
    final badge = LifecycleEngine.getBadge(currentExam);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExamFormScreen(examToEdit: currentExam)))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteExam),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(currentExam.examName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          if (currentExam.advertisementNo != null && currentExam.advertisementNo!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4.0, bottom: 8.0), child: Text(currentExam.advertisementNo!, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold))),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8.0, runSpacing: 8.0,
              children: [
                Chip(avatar: Icon(badge.icon, size: 16, color: badge.color), label: Text(badge.text, style: TextStyle(color: badge.color, fontWeight: FontWeight.bold)), backgroundColor: badge.color.withOpacity(0.1), side: BorderSide(color: badge.color.withOpacity(0.5))),
                if (currentExam.portalUrl != null && currentExam.portalUrl!.isNotEmpty)
                  FilledButton.icon(onPressed: () => _launchUrl(currentExam.portalUrl!), icon: const Icon(Icons.open_in_browser, size: 18), label: const Text('Portal')),
              ],
            ),
          ),

          const Divider(height: 32),
          const Text('Journey Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(children: [const Icon(Icons.app_registration, color: Colors.blue, size: 24), Expanded(child: Container(width: 2, color: Colors.grey.shade300))]),
                const SizedBox(width: 16),
                Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 24.0), child: Card(elevation: 0, color: Colors.blue.withOpacity(0.1), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Application Window', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${_formatDate(currentExam.applicationStartDate)} to ${_formatDate(currentExam.applicationEndDate)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13))]))))),
              ],
            ),
          ),

          _buildDynamicStepper(currentExam),

          const Divider(height: 32),
          const Text('Credentials Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person), const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentExam.usernameType ?? 'Username / ID', style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(currentExam.username?.isNotEmpty == true ? currentExam.username! : 'Not set', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])),
                      if (currentExam.username?.isNotEmpty == true) IconButton(icon: const Icon(Icons.copy), onPressed: () => _copyToClipboard(currentExam.username!, 'Username')),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.lock), const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Password', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(currentExam.password?.isNotEmpty == true ? (_obscurePassword ? '••••••••' : currentExam.password!) : 'Not set', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])),
                      if (currentExam.password?.isNotEmpty == true) ...[
                        IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                        IconButton(icon: const Icon(Icons.copy), onPressed: () => _copyToClipboard(currentExam.password!, 'Password')),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (currentExam.notes != null && currentExam.notes!.isNotEmpty) ...[
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)), const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Text(currentExam.notes!)), const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}