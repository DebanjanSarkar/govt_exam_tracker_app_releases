import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exam_provider.dart';
import '../../core/services/excel_export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;

  int? _startYear;
  int? _endYear;
  List<int> _availableYears = [];

  // FIXED: Added 'Additional Info' to the master list
  final Map<String, bool> _fields = {
    'Exam Name': true,
    'Target Post': true,
    'Advt No': true,
    'Status': true,
    'Syllabus Progress': true,
    'App Start Date': true,
    'App End Date': true,
    'Prelims Date': true,
    'Mains Date': false,
    'Skill Test Date': false,
    'Interview Date': false,
    'Final Result Date': false,
    'Username': false,
    'Password': false,
    'Portal URL': false,
    'Notes': false,
    'Additional Info': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  void _fetchYears() {
    final examsState = ref.read(examListProvider);
    final Set<int> years = {DateTime.now().year};
    if (examsState is AsyncData) {
      for (var exam in examsState.value!) {
        years.add(exam.applicationEndDate?.year ?? exam.createdAt.year);
      }
    }
    _availableYears = years.toList()..sort();
    if (_availableYears.isNotEmpty) {
      _startYear = _availableYears.first;
      _endYear = _availableYears.last;
    }
  }

  bool get _isAllSelected => !_fields.values.contains(false);

  void _toggleAll(bool? value) {
    if (value == null) return;
    setState(() {
      _fields.updateAll((key, _) => value);
    });
  }

  Future<void> _exportData() async {
    if (!_fields.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one field to export.'), backgroundColor: Colors.red));
      return;
    }

    final repository = ref.read(examRepositoryProvider);
    final allExams = await repository.getAllExams();

    final filteredExams = allExams.where((e) {
      int y = e.applicationEndDate?.year ?? e.createdAt.year;
      return y >= _startYear! && y <= _endYear!;
    }).toList();

    if (filteredExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No exams found in this timeframe!'), backgroundColor: Colors.orange));
      return;
    }

    if (filteredExams.length > 1000) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Massive Export Detected!'),
          content: Text(
              'You are about to export ${filteredExams.length} exams.\n\n'
                  'To ensure your phone runs smoothly without freezing, it is highly recommended to export your data in 1 or 2 year batches.\n\n'
                  'Do you still want to generate this massive file now?'
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Export Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isExporting = true);

    try {
      await ExcelExportService.exportToExcel(filteredExams, _fields);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export ready! Choose where to save it.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export to Excel')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Colors.green.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.table_view, color: Colors.green, size: 48),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Data Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Generate a premium Excel file with dynamic Dropdowns and Colors.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text('Select Timeframe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.blue.withOpacity(0.05),
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Text('From:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _startYear,
                          underline: const SizedBox(),
                          items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _startYear = val;
                                if (_startYear! > _endYear!) _endYear = _startYear;
                              });
                            }
                          },
                        ),
                        const Spacer(),
                        const Text('To:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _endYear,
                          underline: const SizedBox(),
                          items: _availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _endYear = val;
                                if (_endYear! < _startYear!) _startYear = _endYear;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Choose Columns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: const Text('Select All Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isAllSelected,
                  onChanged: _toggleAll,
                  activeColor: Colors.blue,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),

                ..._fields.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key, style: const TextStyle(fontSize: 15)),
                    value: _fields[key],
                    onChanged: (val) => setState(() => _fields[key] = val!),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.all(16),
              ),
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.download),
              label: Text(_isExporting ? 'Generating Native Excel...' : 'Export to Excel (.xlsx)', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}