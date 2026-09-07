import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = "govt_exam_tracker.db";
  static const int _databaseVersion = 7; // BUMPED TO V7 FOR ADVANCED ALARMS
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
        frequency TEXT NOT NULL DEFAULT 'day',
        weekdays TEXT,
        end_type TEXT NOT NULL DEFAULT 'never',
        end_date TEXT,
        end_phase TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES $tableExams (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_exam_id ON $tableReminders (exam_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await db.execute('ALTER TABLE $tableExams ADD COLUMN advertisement_no TEXT');
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableExams ADD COLUMN has_mains INTEGER NOT NULL DEFAULT 0');
      // ... (Rest of V3)
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $tableExams ADD COLUMN exam_pattern_data TEXT');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN syllabus_data TEXT');
    }
    if (oldVersion < 5) await db.execute('ALTER TABLE $tableExams ADD COLUMN target_post TEXT');
    if (oldVersion < 6) await _createRemindersTable(db);

    if (oldVersion < 7) {
      // V7 Migration: Add Advanced Cron Fields
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN interval INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN frequency TEXT NOT NULL DEFAULT "day"');
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_type TEXT NOT NULL DEFAULT "never"');
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_date TEXT');
      await db.execute('ALTER TABLE $tableReminders ADD COLUMN end_phase TEXT');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}