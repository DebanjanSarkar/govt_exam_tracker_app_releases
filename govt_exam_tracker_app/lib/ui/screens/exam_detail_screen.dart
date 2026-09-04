import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/exam_model.dart';
import '../../core/utils/lifecycle_engine.dart';
import '../../providers/exam_provider.dart';
import 'exam_form_screen.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final ExamModel exam;
  const ExamDetailScreen({super.key, required this.exam});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  bool _obscurePassword = true;

  String _formatDate(DateTime? date) => date == null ? 'Not announced' : DateFormat('dd MMM yyyy').format(date);

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
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: Text(currentExam.advertisementNo!, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),

          const SizedBox(height: 12),

          // FIXED: Used a full-width Wrap instead of Row to prevent Overflow on smaller devices
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Chip(
                    avatar: Icon(badge.icon, size: 16, color: badge.color),
                    label: Text(badge.text, style: TextStyle(color: badge.color, fontWeight: FontWeight.bold)),
                    backgroundColor: badge.color.withOpacity(0.1),
                    side: BorderSide(color: badge.color.withOpacity(0.5))
                ),
                if (currentExam.portalUrl != null && currentExam.portalUrl!.isNotEmpty)
                  FilledButton.icon(
                      onPressed: () => _launchUrl(currentExam.portalUrl!),
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Portal')
                  ),
              ],
            ),
          ),

          const Divider(height: 32),
          const Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.app_registration), title: const Text('Application Deadline'), subtitle: Text(_formatDate(currentExam.applicationEndDate))),
                ListTile(leading: const Icon(Icons.event), title: const Text('Prelims Exam Date'), subtitle: Text(_formatDate(currentExam.examDate))),
                if (currentExam.mainsExamDate != null) ListTile(leading: const Icon(Icons.event_available), title: const Text('Mains Exam Date'), subtitle: Text(_formatDate(currentExam.mainsExamDate))),
                if (currentExam.resultDate != null) ListTile(leading: const Icon(Icons.emoji_events), title: const Text('Result Date'), subtitle: Text(_formatDate(currentExam.resultDate))),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
          if (currentExam.additionalInfo != null && currentExam.additionalInfo!.isNotEmpty) ...[
            const Text('Additional Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)), const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: Text(currentExam.additionalInfo!)), const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}