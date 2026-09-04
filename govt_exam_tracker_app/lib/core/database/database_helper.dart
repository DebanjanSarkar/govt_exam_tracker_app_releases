import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const String _databaseName = "govt_exam_tracker.db";
  // BUMPED TO V4 FOR SYLLABUS & EXAM PATTERN JSON STORAGE
  static const int _databaseVersion = 4;
  static const String tableExams = "exams";

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

    await db.execute('CREATE INDEX idx_status ON $tableExams (status)');
    await db.execute('CREATE INDEX idx_app_end ON $tableExams (application_end_date)');
    await db.execute('CREATE INDEX idx_exam_date ON $tableExams (exam_date)');
    await db.execute('CREATE INDEX idx_is_deleted ON $tableExams (is_deleted)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableExams ADD COLUMN advertisement_no TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableExams ADD COLUMN has_mains INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN has_skill_test INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN has_interview INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN has_dv INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN skill_test_date TEXT');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN interview_date TEXT');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN dv_date TEXT');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN phase_states TEXT');
    }
    if (oldVersion < 4) {
      // V4 Migration: Storage for AI-generated Syllabus & Patterns
      await db.execute('ALTER TABLE $tableExams ADD COLUMN exam_pattern_data TEXT');
      await db.execute('ALTER TABLE $tableExams ADD COLUMN syllabus_data TEXT');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}