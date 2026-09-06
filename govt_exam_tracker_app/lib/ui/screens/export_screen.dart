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

  // The Master List of all available fields
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
  };

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

    setState(() => _isExporting = true);

    try {
      final repository = ref.read(examRepositoryProvider);
      final allExams = await repository.getAllExams();

      if (allExams.isEmpty) {
        throw Exception('You have no exams to export!');
      }

      await ExcelExportService.exportToExcel(allExams, _fields);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export ready! Choose where to save it.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      }
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
                      Text('Export your data to an Excel (.xlsx) file. Exams will be neatly organized into separate tabs by year.', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                CheckboxListTile(
                  title: const Text('Select All Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  value: _isAllSelected,
                  onChanged: _toggleAll,
                  activeColor: Colors.blue,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const Divider(),
                const Text('Choose Columns to Export:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),

                ..._fields.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key, style: const TextStyle(fontSize: 15)),
                    value: _fields[key],
                    onChanged: (val) {
                      setState(() {
                        _fields[key] = val!;
                      });
                    },
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
              label: Text(_isExporting ? 'Generating Excel...' : 'Export to Excel (.xlsx)', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}