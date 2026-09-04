import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/exam_status.dart';
import '../../providers/exam_provider.dart';
import '../../core/services/ai_parser_service.dart';
import '../../providers/ai_cooldown_provider.dart';
import '../../core/constants/app_constants.dart';

class ExamFormScreen extends ConsumerStatefulWidget {
  final ExamModel? examToEdit;
  const ExamFormScreen({super.key, this.examToEdit});

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAiProcessing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _advNoCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _userTypeCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _infoCtrl;

  ApplicationStatus _status = ApplicationStatus.notApplied;
  DateTime? _appStartDate;
  DateTime? _appEndDate;
  DateTime? _examDate;

  bool _hasMains = false;
  bool _hasSkillTest = false;
  bool _hasInterview = false;
  bool _hasDV = false;

  DateTime? _mainsDate;
  DateTime? _skillDate;
  DateTime? _interviewDate;
  DateTime? _dvDate;
  DateTime? _resultDate;

  @override
  void initState() {
    super.initState();
    final e = widget.examToEdit;
    _nameCtrl = TextEditingController(text: e?.examName ?? '');
    _advNoCtrl = TextEditingController(text: e?.advertisementNo ?? '');
    _urlCtrl = TextEditingController(text: e?.portalUrl ?? '');
    _userTypeCtrl = TextEditingController(text: e?.usernameType ?? 'Registration No');
    _usernameCtrl = TextEditingController(text: e?.username ?? '');
    _passwordCtrl = TextEditingController(text: e?.password ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _infoCtrl = TextEditingController(text: e?.additionalInfo ?? '');

    _status = e?.status ?? ApplicationStatus.notApplied;
    _appStartDate = e?.applicationStartDate;
    _appEndDate = e?.applicationEndDate;
    _examDate = e?.examDate;

    _hasMains = e?.hasMains ?? false;
    _hasSkillTest = e?.hasSkillTest ?? false;
    _hasInterview = e?.hasInterview ?? false;
    _hasDV = e?.hasDV ?? false;

    _mainsDate = e?.mainsExamDate;
    _skillDate = e?.skillTestDate;
    _interviewDate = e?.interviewDate;
    _dvDate = e?.dvDate;
    _resultDate = e?.resultDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _advNoCtrl.dispose(); _urlCtrl.dispose();
    _userTypeCtrl.dispose(); _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _notesCtrl.dispose(); _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPdfWithAi() async {
    final cooldownLeft = ref.read(aiCooldownProvider);
    if (_isAiProcessing || cooldownLeft > 0) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final userKey = prefs.getString(AppConstants.prefsApiKey);

    if (userKey == null || userKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your free Groq API Key in "AI Settings" first!'), backgroundColor: Colors.red));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _isAiProcessing = true);
      try {
        final extractedData = await AiParserService.parseNotificationPdf(File(result.files.single.path!), userKey);
        if (extractedData != null) {
          setState(() {
            if (extractedData['examName'] != null) _nameCtrl.text = extractedData['examName'];
            if (extractedData['advertisementNo'] != null) _advNoCtrl.text = extractedData['advertisementNo'];
            if (extractedData['portalUrl'] != null) _urlCtrl.text = extractedData['portalUrl'];
            if (extractedData['notes'] != null) _notesCtrl.text = extractedData['notes'];

            if (extractedData['appStartDate'] != null) _appStartDate = DateTime.tryParse(extractedData['appStartDate']);
            if (extractedData['appEndDate'] != null) _appEndDate = DateTime.tryParse(extractedData['appEndDate']);
            if (extractedData['examDate'] != null) _examDate = DateTime.tryParse(extractedData['examDate']);

            if (extractedData['hasMains'] != null) _hasMains = extractedData['hasMains'];
            if (extractedData['hasSkillTest'] != null) _hasSkillTest = extractedData['hasSkillTest'];
            if (extractedData['hasInterview'] != null) _hasInterview = extractedData['hasInterview'];
            if (extractedData['hasDV'] != null) _hasDV = extractedData['hasDV'];
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Auto-fill complete!'), backgroundColor: Colors.purple));
        }
        ref.read(aiCooldownProvider.notifier).startGlobalCooldown();
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('RATE_LIMIT')) errorMsg = 'Too many requests. Please wait for the cooldown.';
        else if (errorMsg.contains('TIMEOUT')) errorMsg = 'The AI took too long. Please try again.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        ref.read(aiCooldownProvider.notifier).startGlobalCooldown();
      } finally {
        if (mounted) setState(() => _isAiProcessing = false);
      }
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initial, Function(DateTime) onPicked) async {
    final date = await showDatePicker(context: context, initialDate: initial ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (date != null) setState(() => onPicked(date));
  }

  void _saveExam() {
    if (!_formKey.currentState!.validate()) return;

    final newExam = ExamModel(
      id: widget.examToEdit?.id,
      examName: _nameCtrl.text.trim(),
      advertisementNo: _advNoCtrl.text.trim(),
      portalUrl: _urlCtrl.text.trim(),
      status: _status,
      applicationStartDate: _appStartDate,
      applicationEndDate: _appEndDate,
      hasMains: _hasMains,
      hasSkillTest: _hasSkillTest,
      hasInterview: _hasInterview,
      hasDV: _hasDV,
      examDate: _examDate,
      mainsExamDate: _mainsDate,
      skillTestDate: _skillDate,
      interviewDate: _interviewDate,
      dvDate: _dvDate,
      resultDate: _resultDate,
      phaseStates: widget.examToEdit?.phaseStates ?? {},
      // CRITICAL: Ensure we do not wipe out pattern/syllabus data when updating the form
      examPatternData: widget.examToEdit?.examPatternData ?? {},
      syllabusData: widget.examToEdit?.syllabusData ?? {},
      usernameType: _userTypeCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      additionalInfo: _infoCtrl.text.trim(),
      createdAt: widget.examToEdit?.createdAt,
    );

    if (widget.examToEdit == null) ref.read(examListProvider.notifier).addExam(newExam);
    else ref.read(examListProvider.notifier).updateExam(newExam);
    Navigator.pop(context);
  }

  Widget _buildDateField(String label, DateTime? value, Function(DateTime) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _pickDate(context, value, onPicked),
        child: InputDecorator(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)), child: Text(value != null ? DateFormat('dd MMM yyyy').format(value) : 'Select Date')),
      ),
    );
  }

  Widget _buildStageToggle(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: (val) => setState(() => onChanged(val!)),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cooldownSeconds = ref.watch(aiCooldownProvider);
    final bool isAiDisabled = _isAiProcessing || cooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.examToEdit == null ? 'Add Exam' : 'Edit Exam'), actions: [IconButton(icon: const Icon(Icons.check), onPressed: _isAiProcessing ? null : _saveExam)]),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.tonalIcon(
                  onPressed: isAiDisabled ? null : _processPdfWithAi,
                  icon: Icon(cooldownSeconds > 0 ? Icons.timer : Icons.auto_awesome, color: isAiDisabled ? Colors.grey : Colors.purple),
                  label: Text(cooldownSeconds > 0 ? 'Wait ${cooldownSeconds}s to use AI globally' : 'Auto-Fill with Notification PDF', style: TextStyle(color: isAiDisabled ? Colors.grey : Colors.purple, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: isAiDisabled ? Colors.grey.withOpacity(0.1) : Colors.purple.withOpacity(0.1)),
                ),
                const SizedBox(height: 24),
                const Text('Basic Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Exam Name *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _advNoCtrl, decoration: const InputDecoration(labelText: 'Advertisement No.', border: OutlineInputBorder(), hintText: 'e.g. Advt. 03/2026')),
                const SizedBox(height: 16),
                DropdownButtonFormField<ApplicationStatus>(value: _status, decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()), items: ApplicationStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList(), onChanged: (val) => setState(() => _status = val!)),
                const SizedBox(height: 16),
                TextFormField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Portal URL', border: OutlineInputBorder()), keyboardType: TextInputType.url),
                const Divider(height: 32),

                const Text('Exam Stages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Toggle the phases that apply to this specific exam.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStageToggle('Mains / CBT-2', _hasMains, (v) => _hasMains = v)),
                    Expanded(child: _buildStageToggle('Skill / Physical', _hasSkillTest, (v) => _hasSkillTest = v)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildStageToggle('Interview', _hasInterview, (v) => _hasInterview = v)),
                    Expanded(child: _buildStageToggle('Doc Verification', _hasDV, (v) => _hasDV = v)),
                  ],
                ),

                const Divider(height: 32),
                const Text('Dates & Deadlines', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _buildDateField('App Start', _appStartDate, (d) => _appStartDate = d)), const SizedBox(width: 12), Expanded(child: _buildDateField('App End', _appEndDate, (d) => _appEndDate = d))]),
                Row(children: [
                  Expanded(child: _buildDateField('Prelims Date', _examDate, (d) => _examDate = d)),
                  const SizedBox(width: 12),
                  Expanded(child: _hasMains ? _buildDateField('Mains Date', _mainsDate, (d) => _mainsDate = d) : const SizedBox.shrink())
                ]),
                Row(children: [
                  Expanded(child: _hasSkillTest ? _buildDateField('Skill Test Date', _skillDate, (d) => _skillDate = d) : const SizedBox.shrink()),
                  const SizedBox(width: 12),
                  Expanded(child: _hasInterview ? _buildDateField('Interview Date', _interviewDate, (d) => _interviewDate = d) : const SizedBox.shrink()),
                ]),
                Row(children: [
                  Expanded(child: _hasDV ? _buildDateField('DV Date', _dvDate, (d) => _dvDate = d) : const SizedBox.shrink()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField('Final Result', _resultDate, (d) => _resultDate = d)),
                ]),

                const Divider(height: 32),
                const Text('Credentials', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(children: [Expanded(flex: 2, child: TextFormField(controller: _userTypeCtrl, decoration: const InputDecoration(labelText: 'ID Type', border: OutlineInputBorder()))), const SizedBox(width: 12), Expanded(flex: 3, child: TextFormField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())))]),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const Divider(height: 32),
                const Text('Extra Notes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Eligibility', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 16),
                TextFormField(controller: _infoCtrl, decoration: const InputDecoration(labelText: 'Additional Info', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 80),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              width: double.infinity,
              child: FilledButton(onPressed: _isAiProcessing ? null : _saveExam, style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text('Save Exam', style: TextStyle(fontSize: 16))),
            ),
          ),

          if (_isAiProcessing) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: Card(child: Padding(padding: EdgeInsets.all(24.0), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.purple), SizedBox(height: 16), Text('AI is reading...', style: TextStyle(fontWeight: FontWeight.bold))]))))),
        ],
      ),
    );
  }
}