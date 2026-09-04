import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../models/exam_model.dart';
import '../models/exam_status.dart';

class ExamRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Fetch all active exams
  Future<List<ExamModel>> getAllExams() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableExams,
      where: 'is_deleted = 0',
      orderBy: 'application_end_date DESC', // FIXED: No longer jumps to top on edit!
    );
    return maps.map((map) => ExamModel.fromMap(map)).toList();
  }

  // Insert a new exam
  Future<int> insertExam(ExamModel exam) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableExams,
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update existing exam
  Future<int> updateExam(ExamModel exam) async {
    final db = await _dbHelper.database;
    final updatedExam = exam.copyWith(updatedAt: DateTime.now());
    return await db.update(
      DatabaseHelper.tableExams,
      updatedExam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  // Soft delete exam (allows syncing deletion with Google Drive)
  Future<int> softDeleteExam(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableExams,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Permanent hard delete
  Future<int> hardDeleteExam(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableExams,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Live Fast Filter & Search (by Exam Name, Notes, or Posts)
  Future<List<ExamModel>> searchExams(String query, {ApplicationStatus? status}) async {
    final db = await _dbHelper.database;
    String whereClause = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (query.trim().isNotEmpty) {
      whereClause += ' AND (exam_name LIKE ? OR notes LIKE ? OR username LIKE ? OR post_names LIKE ?)';
      final searchPattern = '%${query.trim()}%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableExams,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => ExamModel.fromMap(map)).toList();
  }

  // Bulk replace (used by Google Drive Pull Sync)
  Future<void> bulkSyncInsert(List<ExamModel> remoteExams) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final exam in remoteExams) {
      batch.insert(
        DatabaseHelper.tableExams,
        exam.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}