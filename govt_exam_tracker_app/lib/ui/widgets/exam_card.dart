import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/lifecycle_engine.dart';
import '../../data/models/exam_model.dart';
import '../screens/exam_detail_screen.dart';

class ExamCard extends StatelessWidget {
  final ExamModel exam;

  const ExamCard({super.key, required this.exam});

  Future<void> _launchPortal(BuildContext context) async {
    if (exam.portalUrl == null || exam.portalUrl!.isEmpty) return;
    if (!await launchUrl(Uri.parse(exam.portalUrl!), mode: LaunchMode.externalApplication)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = LifecycleEngine.getBadge(exam);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExamDetailScreen(exam: exam))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: badge.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: badge.color.withOpacity(0.5))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(badge.icon, size: 16, color: badge.color), const SizedBox(width: 6), Flexible(child: Text(badge.text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badge.color), overflow: TextOverflow.ellipsis))],
                      ),
                    ),
                  ),
                  if (exam.portalUrl != null && exam.portalUrl!.isNotEmpty) IconButton(icon: const Icon(Icons.open_in_browser), color: theme.colorScheme.primary, constraints: const BoxConstraints(), padding: EdgeInsets.zero, onPressed: () => _launchPortal(context)),
                ],
              ),
              const SizedBox(height: 12),
              Text(exam.examName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2)),

              // NEW: ADVERTISEMENT NUMBER
              if (exam.advertisementNo != null && exam.advertisementNo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(exam.advertisementNo!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (exam.username != null && exam.username!.isNotEmpty) ...[
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600), const SizedBox(width: 4), Expanded(child: Text('${exam.usernameType ?? 'ID'}: ${exam.username}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),
                  ],
                  if (exam.examDate != null) ...[
                    Icon(Icons.event, size: 16, color: Colors.grey.shade600), const SizedBox(width: 4), Text('${exam.examDate!.day}/${exam.examDate!.month}/${exam.examDate!.year}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}