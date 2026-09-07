import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = "govt_exam_tracker.db";
  static const int _databaseVersion = 8; // BUMPED TO V8 FOR HIGH PRIORITY ALARMS
  static const String tableExams = "exams";
  static const String tableReminders = "reminders";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableExams (
        id TEXT PRIMARY KEY,
        exam_name TEXT NOT NULL,
        advertisement_no TEXT,
        target_post TEXT,
        portal_url TEXT,
        status TEXT NOT NULL,
        application_start_date TEXT,
        application_end_date TEXT,
        has_mains INTEGER NOT NULL DEFAULT 0,
        has_skill_test INTEGER NOT NULL DEFAULT 0,
        has_interview INTEGER NOT NULL DEFAULT 0,
        has_dv INTEGER NOT NULL DEFAULT 0,
        exam_date TEXT,
        mains_exam_date TEXT,
        skill_test_date TEXT,
        interview_date TEXT,
        dv_date TEXT,
        result_date TEXT,
        phase_states TEXT,
        exam_pattern_data TEXT,
        syllabus_data TEXT,
        username_type TEXT,
        username TEXT,
        password TEXT,
        notes TEXT,
        additional_info TEXT,
        post_names TEXT,
        notification_pdf_path TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createRemindersTable(db);

    await db.execute('CREATE INDEX idx_status ON $tableExams (status)');
    await db.execute('CREATE INDEX idx_app_end ON $tableExams (application_end_date)');
  }

  Future<void> _createRemindersTable(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE $tableReminders (
          id TEXT PRIMARY KEY,
          exam_id TEXT NOT NULL,
          exam_name TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          time TEXT NOT NULL,
          repeat_type TEXT NOT NULL,
          interval INTEGER NOT NULL DEFAULT 1,
          frequency TEXT NOT NULL DEFAULT "day",
          weekdays TEXT,
          end_type TEXT NOT NULL DEFAULT "never",
          end_date TEXT,
          end_phase TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_high_priority INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (exam_id) REFERENCES $tableExams (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_exam_id ON $tableReminders (exam_id)');
    } catch (_) {}
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { try { await db.execute('ALTER TABLE $tableExams ADD COLUMN advertisement_no TEXT'); } catch (_) {} }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN has_mains INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN has_skill_test INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN has_interview INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN has_dv INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN skill_test_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN interview_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN dv_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN phase_states TEXT'); } catch (_) {}
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN exam_pattern_data TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableExams ADD COLUMN syllabus_data TEXT'); } catch (_) {}
    }
    if (oldVersion < 5) { try { await db.execute('ALTER TABLE $tableExams ADD COLUMN target_post TEXT'); } catch (_) {} }
    if (oldVersion < 6) { await _createRemindersTable(db); }
    if (oldVersion == 6) {
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN interval INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN frequency TEXT NOT NULL DEFAULT "day"'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_type TEXT NOT NULL DEFAULT "never"'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_phase TEXT'); } catch (_) {}
    }
    if (oldVersion < 8) {
      // V8 Migration: Add High Priority Toggle
      try { await db.execute('ALTER TABLE $tableReminders ADD COLUMN is_high_priority INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}