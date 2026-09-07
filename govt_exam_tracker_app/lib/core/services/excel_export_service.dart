import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../data/models/exam_model.dart';

class ExcelExportService {
  static const MethodChannel _channel = MethodChannel('com.debanjan_sarkar.govt_exam_tracker_app/excel');

  // FIXED: Outputting raw computer date format so Kotlin can parse it natively
  static String _formatDate(DateTime? date) => date == null ? '' : DateFormat('yyyy-MM-dd').format(date);

  static String _getSyllabusProgress(ExamModel exam) {
    if (exam.syllabusData.isEmpty) return '0%';
    int total = 0; int completed = 0;
    exam.syllabusData.forEach((_, subjects) {
      if (subjects is Map) {
        subjects.forEach((_, topics) {
          if (topics is List) {
            for (var topic in topics) {
              total++;
              if (topic['completed'] == true) completed++;
            }
          }
        });
      }
    });
    if (total == 0) return '0%';
    return '${((completed / total) * 100).toInt()}%';
  }

  static Future<void> exportToExcel(List<ExamModel> allExams, Map<String, bool> selectedFields) async {
    List<String> activeColumns = [];
    selectedFields.forEach((key, isSelected) {
      if (isSelected) activeColumns.add(key);
    });

    Map<String, List<List<String>>> sheetsData = {};

    for (var exam in allExams) {
      String year = (exam.applicationEndDate?.year ?? exam.createdAt.year).toString();
      if (!sheetsData.containsKey(year)) sheetsData[year] = [];

      List<String> rowData = [];
      for (String col in activeColumns) {
        switch (col) {
          case 'Exam Name': rowData.add(exam.examName); break;
          case 'Target Post': rowData.add(exam.targetPost ?? ''); break;
          case 'Advt No': rowData.add(exam.advertisementNo ?? ''); break;
          case 'Status': rowData.add(exam.status.displayName); break;
          case 'Syllabus Progress': rowData.add(_getSyllabusProgress(exam)); break;
          case 'App Start Date': rowData.add(_formatDate(exam.applicationStartDate)); break;
          case 'App End Date': rowData.add(_formatDate(exam.applicationEndDate)); break;
          case 'Prelims Date': rowData.add(_formatDate(exam.examDate)); break;
          case 'Mains Date': rowData.add(_formatDate(exam.mainsExamDate)); break;
          case 'Skill Test Date': rowData.add(_formatDate(exam.skillTestDate)); break;
          case 'Interview Date': rowData.add(_formatDate(exam.interviewDate)); break;
          case 'Final Result Date': rowData.add(_formatDate(exam.resultDate)); break;
          case 'Username': rowData.add(exam.username ?? ''); break;
          case 'Password': rowData.add(exam.password ?? ''); break;
          case 'Portal URL': rowData.add(exam.portalUrl ?? ''); break;
          case 'Notes': rowData.add(exam.notes ?? ''); break;
          case 'Additional Info': rowData.add(exam.additionalInfo ?? ''); break; // FIXED: Added missing field
          default: rowData.add('');
        }
      }
      sheetsData[year]!.add(rowData);
    }

    final String jsonPayload = jsonEncode({
      "columns": activeColumns,
      "sheets": sheetsData
    });

    try {
      final String? filePath = await _channel.invokeMethod('generateNativeExcel', {"payload": jsonPayload});
      if (filePath != null && filePath.isNotEmpty) {
        await Share.shareXFiles([XFile(filePath)], text: 'My Govt Exams Tracker Backup');
      } else {
        throw Exception('Native generation failed.');
      }
    } on PlatformException catch (e) {
      if (e.code == "OOM_ERROR") {
        throw Exception("This export is too large for your phone's memory. Please export a smaller 1 or 2 year timeframe.");
      }
      throw Exception('Android Error: ${e.message}');
    }
  }
}