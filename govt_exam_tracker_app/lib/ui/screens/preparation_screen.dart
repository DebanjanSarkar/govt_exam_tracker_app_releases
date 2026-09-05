import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ai_cooldown_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/syllabus_parser_service.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  final ExamModel exam;
  const PreparationScreen({super.key, required this.exam});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen> {
  bool _isGeneratingSyllabus = false;

  void _generateSyllabusAi(ExamModel currentExam, {bool isRegenerating = false}) async {
    if (isRegenerating) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          // FIXED: Wrapped Text in Expanded to prevent Right Overflow error
          title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Expanded(child: Text('Regenerate Syllabus?'))]),
          content: const Text('This will overwrite your current exam pattern and syllabus. All your checked progress will be reset. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => Navigator.pop(context, true), child: const Text('Regenerate')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final cooldownLeft = ref.read(aiCooldownProvider);
    if (cooldownLeft > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI is cooling down. Please wait $cooldownLeft seconds.'), backgroundColor: Colors.orange));
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final userKey = prefs.getString(AppConstants.prefsApiKey);
    if (userKey == null || userKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add your Groq or Gemini API Key in settings first!'), backgroundColor: Colors.red));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isGeneratingSyllabus = true);
      try {
        final extractedData = await SyllabusParserService.generateSyllabusAndPattern(File(result.files.single.path!), currentExam, userKey);

        if (extractedData != null) {
          final updatedExam = currentExam.copyWith(
            examPatternData: extractedData['examPatternData'],
            syllabusData: extractedData['syllabusData'],
          );
          ref.read(examListProvider.notifier).updateExam(updatedExam);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Syllabus & Pattern Successfully Extracted!'), backgroundColor: Colors.green));
        }
        ref.read(aiCooldownProvider.notifier).startGlobalCooldown();
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('RATE_LIMIT')) errorMsg = 'Daily Token Limit Reached! Try your Gemini Key instead.';
        else if (errorMsg.contains('TIMEOUT')) errorMsg = 'The AI took too long. Please try again.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        ref.read(aiCooldownProvider.notifier).startGlobalCooldown();
      } finally {
        if (mounted) setState(() => _isGeneratingSyllabus = false);
      }
    }
  }

  void _toggleTopicCompletion(ExamModel currentExam, String stage, String subject, int topicIndex, bool? newValue) {
    if (newValue == null) return;
    final updatedSyllabus = jsonDecode(jsonEncode(currentExam.syllabusData)) as Map<String, dynamic>;
    updatedSyllabus[stage][subject][topicIndex]['completed'] = newValue;
    ref.read(examListProvider.notifier).updateExam(currentExam.copyWith(syllabusData: updatedSyllabus));
  }

  List<String> _getSortedStages(ExamModel exam) {
    final stages = <String>{};
    stages.addAll(exam.examPatternData.keys);
    stages.addAll(exam.syllabusData.keys);

    final order = ['Prelims', 'Mains', 'Skill Test', 'Interview', 'Document Verification'];
    final result = stages.toList();
    result.sort((a, b) {
      int idxA = order.indexOf(a); int idxB = order.indexOf(b);
      if (idxA == -1) idxA = 99; if (idxB == -1) idxB = 99;
      return idxA.compareTo(idxB);
    });
    return result;
  }

  Widget _buildStageView(ExamModel exam, String stage) {
    final pattern = exam.examPatternData[stage];
    final syllabus = exam.syllabusData[stage];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pattern is List && pattern.isNotEmpty) ...[
          const Text('Exam Pattern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 12),
          Card(
            elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pattern.map((sec) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(sec['subject']?.toString() ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w600))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${sec['questions'] ?? '-'} Qs', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('${sec['marks'] ?? '-'} Marks', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (syllabus is Map && syllabus.isNotEmpty) ...[
          const Text('Detailed Syllabus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 12),
          ...syllabus.entries.map((subjectEntry) {
            final subject = subjectEntry.key;
            final topics = subjectEntry.value;
            if (topics is! List) return const SizedBox.shrink();

            int completedInSub = topics.where((t) => t['completed'] == true).length;
            double progress = topics.isNotEmpty ? completedInSub / topics.length : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 8.0, right: 32.0), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, color: AppTheme.successColor, minHeight: 6, borderRadius: BorderRadius.circular(3))),
                  children: List.generate(topics.length, (index) {
                    final topic = topics[index];
                    final isCompleted = topic['completed'] == true;
                    return CheckboxListTile(
                      title: Text(topic['topic'].toString(), style: TextStyle(fontSize: 14, color: isCompleted ? Colors.grey : Colors.black87, decoration: isCompleted ? TextDecoration.lineThrough : null)),
                      value: isCompleted, activeColor: AppTheme.successColor, controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) => _toggleTopicCompletion(exam, stage, subject, index, val),
                    );
                  }),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 40),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              const Text('Missing a stage or made a mistake?', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isGeneratingSyllabus ? null : () => _generateSyllabusAi(exam, isRegenerating: true),
                icon: const Icon(Icons.refresh, size: 18), label: const Text('Regenerate Syllabus & Pattern'), style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final examsState = ref.watch(examListProvider);
    final currentExam = examsState.valueOrNull?.firstWhere((e) => e.id == widget.exam.id, orElse: () => widget.exam) ?? widget.exam;

    final stages = _getSortedStages(currentExam);
    final hasData = stages.isNotEmpty;

    return Stack(
      children: [
        if (hasData)
          DefaultTabController(
            length: stages.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Preparation Room'),
                bottom: TabBar(isScrollable: true, labelColor: Colors.white, unselectedLabelColor: Colors.white60, indicatorColor: Colors.white, indicatorWeight: 3, tabs: stages.map((s) => Tab(text: s.toUpperCase())).toList()),
              ),
              body: TabBarView(children: stages.map((stage) => _buildStageView(currentExam, stage)).toList()),
            ),
          )
        else
          Scaffold(
            appBar: AppBar(title: const Text('Preparation Room')),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, color: Colors.purple, size: 64), const SizedBox(height: 24),
                  const Text('No Syllabus Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), const SizedBox(height: 12),
                  const Text('Ensure you have selected the correct Exam Stages (Mains, Interview) in the Edit Exam form.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)), const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 54, child: FilledButton.icon(onPressed: _isGeneratingSyllabus ? null : () => _generateSyllabusAi(currentExam), icon: const Icon(Icons.auto_awesome), label: const Text('Extract Pattern from PDF', style: TextStyle(fontSize: 16)), style: FilledButton.styleFrom(backgroundColor: Colors.purple))),
                ],
              ),
            ),
          ),

        if (_isGeneratingSyllabus)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.purple), SizedBox(height: 24),
                      Text('Reading PDF & Internet...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 8),
                      Text('This takes about 10-15 seconds.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}