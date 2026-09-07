import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/reminder_model.dart';
import '../../providers/reminder_provider.dart';

class AddReminderSheet extends ConsumerStatefulWidget {
  final ExamModel exam;
  final ReminderModel? reminderToEdit;

  const AddReminderSheet({super.key, required this.exam, this.reminderToEdit});

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _intervalCtrl;

  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeatType = 'none';
  int _interval = 1;
  String _frequency = 'week';
  List<int> _selectedDays = [];

  String _endType = 'never';
  DateTime? _endDate;
  String? _endPhase;

  final Map<int, String> _dayMap = {
    1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'
  };

  @override
  void initState() {
    super.initState();
    final r = widget.reminderToEdit;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _intervalCtrl = TextEditingController(text: (r?.interval ?? 1).toString());

    if (r != null) {
      _selectedTime = TimeOfDay(hour: r.time.hour, minute: r.time.minute);
      _repeatType = r.repeatType;
      _interval = r.interval;
      _frequency = r.frequency;
      _selectedDays = List.from(r.weekdays);
      _endType = r.endType;
      _endDate = r.endDate;
      _endPhase = r.endPhase;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _endDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030)
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _endType = 'date';
      });
    }
  }

  void _saveReminder() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title.'), backgroundColor: Colors.red));
      return;
    }
    if (_repeatType == 'custom' && _frequency == 'week' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one day for weekly repeat.'), backgroundColor: Colors.red));
      return;
    }
    if (_endType == 'date' && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an end date.'), backgroundColor: Colors.red));
      return;
    }
    if (_endType == 'phase' && _endPhase == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an end phase.'), backgroundColor: Colors.red));
      return;
    }

    if (widget.reminderToEdit != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Edit Alarm?'),
          content: const Text('Are you sure you want to modify this alarm? This will reschedule all future occurrences.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final now = DateTime.now();
    DateTime anchorTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    final reminder = ReminderModel(
      id: widget.reminderToEdit?.id,
      examId: widget.exam.id,
      examName: widget.exam.examName,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      time: anchorTime,
      repeatType: _repeatType,
      interval: int.tryParse(_intervalCtrl.text) ?? 1,
      frequency: _frequency,
      weekdays: _selectedDays,
      endType: _endType,
      endDate: _endType == 'date' ? _endDate : null,
      endPhase: _endType == 'phase' ? _endPhase : null,
      isActive: widget.reminderToEdit?.isActive ?? true,
    );

    if (widget.reminderToEdit == null) {
      ref.read(reminderListProvider.notifier).addReminder(reminder);
    } else {
      ref.read(reminderListProvider.notifier).updateReminder(reminder);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    List<DropdownMenuItem<String>> phaseItems = [
      const DropdownMenuItem(value: 'prelims', child: Text('Prelims / CBT-1')),
    ];
    if (widget.exam.hasMains) phaseItems.add(const DropdownMenuItem(value: 'mains', child: Text('Mains / CBT-2')));
    if (widget.exam.hasSkillTest) phaseItems.add(const DropdownMenuItem(value: 'skill', child: Text('Skill / Physical')));
    if (widget.exam.hasInterview) phaseItems.add(const DropdownMenuItem(value: 'interview', child: Text('Interview')));
    if (widget.exam.hasDV) phaseItems.add(const DropdownMenuItem(value: 'dv', child: Text('Document Verification')));
    phaseItems.add(const DropdownMenuItem(value: 'result', child: Text('Final Result')));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reminderToEdit == null ? 'Add Routine Alarm' : 'Edit Routine Alarm', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title (e.g. Study Quants)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Alert Time', border: OutlineInputBorder()),
                      child: Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // FIXED: Prevents text overflow on small screens
                    value: _repeatType,
                    decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Once')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom...')),
                    ],
                    onChanged: (val) => setState(() => _repeatType = val!),
                  ),
                ),
              ],
            ),

            if (_repeatType == 'custom') ...[
              const Divider(height: 32),
              const Text('Custom Recurrence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Repeats every', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _intervalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // FIXED: Forces the dropdown to obey the screen limits!
                      value: _frequency,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('Day(s)')),
                        DropdownMenuItem(value: 'week', child: Text('Week(s)')),
                        DropdownMenuItem(value: 'month', child: Text('Month(s)')),
                      ],
                      onChanged: (val) => setState(() => _frequency = val!),
                    ),
                  ),
                ],
              ),

              if (_frequency == 'week') ...[
                const SizedBox(height: 16),
                const Text('Repeats on:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _dayMap.entries.map((entry) {
                    final isSelected = _selectedDays.contains(entry.key);
                    return ChoiceChip(
                      label: Text(entry.value, style: TextStyle(color: isSelected ? Colors.purple : theme.colorScheme.onSurface)),
                      selected: isSelected,
                      selectedColor: Colors.purple.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: true,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedDays.add(entry.key);
                          else _selectedDays.remove(entry.key);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
              const Text('Ends:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),

              RadioListTile<String>(
                title: const Text('Never'),
                value: 'never',
                groupValue: _endType,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.purple,
                onChanged: (val) => setState(() => _endType = val!),
              ),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('On Date'),
                      value: 'date',
                      groupValue: _endType,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.purple,
                      onChanged: (val) => setState(() => _endType = val!),
                    ),
                  ),
                  if (_endType == 'date')
                    TextButton.icon(
                      onPressed: _pickEndDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Select Date'),
                    )
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('After Phase'),
                      value: 'phase',
                      groupValue: _endType,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.purple,
                      onChanged: (val) => setState(() {
                        _endType = val!;
                        _endPhase ??= 'prelims';
                      }),
                    ),
                  ),
                  if (_endType == 'phase')
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true, // FIXED
                        value: _endPhase,
                        items: phaseItems,
                        onChanged: (val) => setState(() => _endPhase = val),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saveReminder,
                child: Text(widget.reminderToEdit == null ? 'Save Alarm' : 'Update Alarm', style: const TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}