import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/exam_status.dart';

class ExcelExportService {

  static String _formatDate(DateTime? date) => date == null ? '' : DateFormat('dd-MMM-yyyy').format(date);

  static String _getSyllabusProgress(ExamModel exam) {
    if (exam.syllabusData.isEmpty) return '0%';
    int total = 0;
    int completed = 0;
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

  // STATUS COLORS
  static ExcelColor _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.notApplied: return ExcelColor.fromHexString('#F1F5F9'); // Slate
      case ApplicationStatus.applied: return ExcelColor.fromHexString('#DBEAFE'); // Blue
      case ApplicationStatus.admitCardOut: return ExcelColor.fromHexString('#FDF08A'); // Darker Yellow
      case ApplicationStatus.examGiven: return ExcelColor.fromHexString('#E9D5FF'); // Purple
      case ApplicationStatus.resultOut: return ExcelColor.fromHexString('#BBF7D0'); // Green
      case ApplicationStatus.archived: return ExcelColor.fromHexString('#E5E5E5'); // Grey
      default: return ExcelColor.fromHexString('#FFFFFF');
    }
  }

  // DYNAMIC CELL STYLER (Handles Conditional Background Colors)
  static CellStyle _getDynamicCellStyle(String columnName, ApplicationStatus status, bool isAlternateRow) {
    ExcelColor bgColor = isAlternateRow ? ExcelColor.fromHexString('#F8FAFC') : ExcelColor.fromHexString('#FFFFFF');
    HorizontalAlign hAlign = HorizontalAlign.Left;
    bool isBold = false;

    // 1. Exam Name -> Light Purple Background
    if (columnName == 'Exam Name') {
      bgColor = ExcelColor.fromHexString('#F3E8FF');
      isBold = true;
    }
    // 2. Prelims & Mains Dates -> Light Yellow Background
    else if (columnName == 'Prelims Date' || columnName == 'Mains Date') {
      bgColor = ExcelColor.fromHexString('#FEF08A');
      hAlign = HorizontalAlign.Center;
    }
    // 3. Status -> Conditional Status Color
    else if (columnName == 'Status') {
      bgColor = _getStatusColor(status);
      hAlign = HorizontalAlign.Center;
      isBold = true;
    }
    // 4. Center align other date/progress columns
    else if (columnName.contains('Date') || columnName == 'Syllabus Progress') {
      hAlign = HorizontalAlign.Center;
    }

    return CellStyle(
      backgroundColorHex: bgColor,
      horizontalAlign: hAlign,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      bold: isBold,
    );
  }

  static double _getColumnWidth(String columnName) {
    switch (columnName) {
      case 'Exam Name': return 35.0;
      case 'Target Post': return 25.0;
      case 'Advt No': return 20.0;
      case 'Status': return 20.0;
      case 'Syllabus Progress': return 18.0;
      case 'Username': return 20.0;
      case 'Password': return 20.0;
      case 'Portal URL': return 40.0;
      case 'Notes': return 60.0;
      default: return 18.0;
    }
  }

  static Future<void> exportToExcel(List<ExamModel> allExams, Map<String, bool> selectedFields) async {
    var excel = Excel.createExcel();

    // Header Style
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'), // Deep Navy Blue
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'), // White Text
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // Group exams by Year
    Map<int, List<ExamModel>> examsByYear = {};
    for (var exam in allExams) {
      int year = exam.applicationEndDate?.year ?? exam.createdAt.year;
      if (!examsByYear.containsKey(year)) {
        examsByYear[year] = [];
      }
      examsByYear[year]!.add(exam);
    }

    // Determine active columns
    List<String> activeColumns = [];
    selectedFields.forEach((key, isSelected) {
      if (isSelected) activeColumns.add(key);
    });

    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.delete(defaultSheet);

    final sortedYears = examsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    for (int year in sortedYears) {
      String sheetName = year.toString();
      Sheet sheet = excel[sheetName];

      // Set Column Widths
      for (int i = 0; i < activeColumns.length; i++) {
        sheet.setColumnWidth(i, _getColumnWidth(activeColumns[i]));
      }

      // Append Headers
      sheet.appendRow(activeColumns.map((e) => TextCellValue(e)).toList());
      for (int i = 0; i < activeColumns.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      // Append Data Rows
      int rowIndex = 1;
      for (var exam in examsByYear[year]!) {
        List<CellValue> rowData = [];

        for (String col in activeColumns) {
          switch (col) {
            case 'Exam Name': rowData.add(TextCellValue(exam.examName)); break;
            case 'Target Post': rowData.add(TextCellValue(exam.targetPost ?? '')); break;
            case 'Advt No': rowData.add(TextCellValue(exam.advertisementNo ?? '')); break;
            case 'Status': rowData.add(TextCellValue(exam.status.displayName)); break;
            case 'Syllabus Progress': rowData.add(TextCellValue(_getSyllabusProgress(exam))); break;
            case 'App Start Date': rowData.add(TextCellValue(_formatDate(exam.applicationStartDate))); break;
            case 'App End Date': rowData.add(TextCellValue(_formatDate(exam.applicationEndDate))); break;
            case 'Prelims Date': rowData.add(TextCellValue(_formatDate(exam.examDate))); break;
            case 'Mains Date': rowData.add(TextCellValue(_formatDate(exam.mainsExamDate))); break;
            case 'Skill Test Date': rowData.add(TextCellValue(_formatDate(exam.skillTestDate))); break;
            case 'Interview Date': rowData.add(TextCellValue(_formatDate(exam.interviewDate))); break;
            case 'Final Result Date': rowData.add(TextCellValue(_formatDate(exam.resultDate))); break;
            case 'Username': rowData.add(TextCellValue(exam.username ?? '')); break;
            case 'Password': rowData.add(TextCellValue(exam.password ?? '')); break;
            case 'Portal URL': rowData.add(TextCellValue(exam.portalUrl ?? '')); break;
            case 'Notes': rowData.add(TextCellValue(exam.notes ?? '')); break;
            default: rowData.add(TextCellValue(''));
          }
        }

        sheet.appendRow(rowData);

        // APPLY CONDITIONAL FORMATTING PER CELL
        for (int i = 0; i < activeColumns.length; i++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex));
          cell.cellStyle = _getDynamicCellStyle(activeColumns[i], exam.status, rowIndex % 2 == 0);
        }

        rowIndex++;
      }
    }

    // Save and Export
    var fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Failed to generate Excel file');

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Govt_Exams_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx');

    await file.writeAsBytes(fileBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'My Govt Exams Tracker Backup');
  }
}