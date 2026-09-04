import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/exam_model.dart';
import '../../core/utils/lifecycle_engine.dart';
import '../../providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
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

  // RESTORED: The Delete Exam Function
  void _deleteExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: const Text('This will move the exam to the trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(examListProvider.notifier).deleteExam(widget.exam.id);
      Navigator.pop(context);
    }
  }

  void _updatePhaseState(ExamModel currentExam, String phaseKey, String newState) {
    // Allows the user to click a stage node and instantly update its status without editing the whole form!
    final updatedPhases = Map<String, String>.from(currentExam.phaseStates);
    updatedPhases[phaseKey] = newState;

    final updatedExam = currentExam.copyWith(phaseStates: updatedPhases);
    ref.read(examListProvider.notifier).updateExam(updatedExam);
  }

  // Beautiful Vertical Node Builder
  Widget _buildTimelineNode(ExamModel currentExam, {
    required String title,
    required DateTime? date,
    required String phaseKey,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final String currentState = currentExam.phaseStates[phaseKey] ?? 'pending';

    Color nodeColor = Colors.grey.shade400;
    IconData nodeIcon = Icons.radio_button_unchecked;

    if (currentState == 'cleared') {
      nodeColor = AppTheme.successColor;
      nodeIcon = Icons.check_circle;
    } else if (currentState == 'failed') {
      nodeColor = AppTheme.dangerColor;
      nodeIcon = Icons.cancel;
    } else if (currentState == 'admit_card') {
      nodeColor = AppTheme.warningColor;
      nodeIcon = Icons.downloading;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Line & Circle
          Column(
            children: [
              Icon(nodeIcon, color: nodeColor, size: 24),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),
          // Right Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(_formatDate(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      // Dropdown to instantly change phase status
                      DropdownButton<String>(
                        value: currentState,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: TextStyle(color: nodeColor, fontWeight: FontWeight.bold, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'admit_card', child: Text('Admit Card Out')),
                          DropdownMenuItem(value: 'cleared', child: Text('Cleared / Passed')),
                          DropdownMenuItem(value: 'failed', child: Text('Failed')),
                        ],
                        onChanged: (val) {
                          if (val != null) _updatePhaseState(currentExam, phaseKey, val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

          // ==========================================
          // DYNAMIC JOURNEY TIMELINE
          // ==========================================
          const Text('Journey Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),

          // Application Registration Node (Fixed)
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

          // Dynamic Nodes based on Form Booleans
          _buildTimelineNode(currentExam, title: 'Prelims / CBT-1', date: currentExam.examDate, phaseKey: 'prelims', isLast: !currentExam.hasMains && !currentExam.hasSkillTest && !currentExam.hasInterview && !currentExam.hasDV && currentExam.resultDate == null),
          if (currentExam.hasMains) _buildTimelineNode(currentExam, title: 'Mains / CBT-2', date: currentExam.mainsExamDate, phaseKey: 'mains', isLast: !currentExam.hasSkillTest && !currentExam.hasInterview && !currentExam.hasDV && currentExam.resultDate == null),
          if (currentExam.hasSkillTest) _buildTimelineNode(currentExam, title: 'Skill / Physical Test', date: currentExam.skillTestDate, phaseKey: 'skill', isLast: !currentExam.hasInterview && !currentExam.hasDV && currentExam.resultDate == null),
          if (currentExam.hasInterview) _buildTimelineNode(currentExam, title: 'Interview', date: currentExam.interviewDate, phaseKey: 'interview', isLast: !currentExam.hasDV && currentExam.resultDate == null),
          if (currentExam.hasDV) _buildTimelineNode(currentExam, title: 'Document Verification', date: currentExam.dvDate, phaseKey: 'dv', isLast: currentExam.resultDate == null),

          // Final Result Node
          if (currentExam.resultDate != null || currentExam.phaseStates.isNotEmpty)
            _buildTimelineNode(currentExam, title: 'Final Result', date: currentExam.resultDate, phaseKey: 'result', isLast: true),

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