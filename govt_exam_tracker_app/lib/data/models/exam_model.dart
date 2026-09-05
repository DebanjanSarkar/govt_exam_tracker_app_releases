import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'exam_status.dart';
export 'exam_status.dart';

class ExamModel {
  final String id;
  final String examName;
  final String? advertisementNo;
  final String? targetPost; // NEW: The specific post/discipline
  final String? portalUrl;
  final ApplicationStatus status;

  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;

  final bool hasMains;
  final bool hasSkillTest;
  final bool hasInterview;
  final bool hasDV;

  final DateTime? examDate;
  final DateTime? mainsExamDate;
  final DateTime? skillTestDate;
  final DateTime? interviewDate;
  final DateTime? dvDate;
  final DateTime? resultDate;

  final Map<String, String> phaseStates;
  final Map<String, dynamic> examPatternData;
  final Map<String, dynamic> syllabusData;

  final String? usernameType;
  final String? username;
  final String? password;
  final String? notes;
  final String? additionalInfo;
  final List<String> postNames;
  final String? notificationPdfPath;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  ExamModel({
    String? id,
    required this.examName,
    this.advertisementNo,
    this.targetPost,
    this.portalUrl,
    this.status = ApplicationStatus.notApplied,
    this.applicationStartDate,
    this.applicationEndDate,
    this.hasMains = false,
    this.hasSkillTest = false,
    this.hasInterview = false,
    this.hasDV = false,
    this.examDate,
    this.mainsExamDate,
    this.skillTestDate,
    this.interviewDate,
    this.dvDate,
    this.resultDate,
    Map<String, String>? phaseStates,
    Map<String, dynamic>? examPatternData,
    Map<String, dynamic>? syllabusData,
    this.usernameType,
    this.username,
    this.password,
    this.notes,
    this.additionalInfo,
    List<String>? postNames,
    this.notificationPdfPath,
    this.reminderEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        phaseStates = phaseStates ?? {},
        examPatternData = examPatternData ?? {},
        syllabusData = syllabusData ?? {},
        postNames = postNames ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ExamModel copyWith({
    String? id,
    String? examName,
    String? advertisementNo,
    String? targetPost,
    String? portalUrl,
    ApplicationStatus? status,
    DateTime? applicationStartDate,
    DateTime? applicationEndDate,
    bool? hasMains,
    bool? hasSkillTest,
    bool? hasInterview,
    bool? hasDV,
    DateTime? examDate,
    DateTime? mainsExamDate,
    DateTime? skillTestDate,
    DateTime? interviewDate,
    DateTime? dvDate,
    DateTime? resultDate,
    Map<String, String>? phaseStates,
    Map<String, dynamic>? examPatternData,
    Map<String, dynamic>? syllabusData,
    String? usernameType,
    String? username,
    String? password,
    String? notes,
    String? additionalInfo,
    List<String>? postNames,
    String? notificationPdfPath,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return ExamModel(
      id: id ?? this.id,
      examName: examName ?? this.examName,
      advertisementNo: advertisementNo ?? this.advertisementNo,
      targetPost: targetPost ?? this.targetPost,
      portalUrl: portalUrl ?? this.portalUrl,
      status: status ?? this.status,
      applicationStartDate: applicationStartDate ?? this.applicationStartDate,
      applicationEndDate: applicationEndDate ?? this.applicationEndDate,
      hasMains: hasMains ?? this.hasMains,
      hasSkillTest: hasSkillTest ?? this.hasSkillTest,
      hasInterview: hasInterview ?? this.hasInterview,
      hasDV: hasDV ?? this.hasDV,
      examDate: examDate ?? this.examDate,
      mainsExamDate: mainsExamDate ?? this.mainsExamDate,
      skillTestDate: skillTestDate ?? this.skillTestDate,
      interviewDate: interviewDate ?? this.interviewDate,
      dvDate: dvDate ?? this.dvDate,
      resultDate: resultDate ?? this.resultDate,
      phaseStates: phaseStates ?? this.phaseStates,
      examPatternData: examPatternData ?? this.examPatternData,
      syllabusData: syllabusData ?? this.syllabusData,
      usernameType: usernameType ?? this.usernameType,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      postNames: postNames ?? this.postNames,
      notificationPdfPath: notificationPdfPath ?? this.notificationPdfPath,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_name': examName,
      'advertisement_no': advertisementNo,
      'target_post': targetPost,
      'portal_url': portalUrl,
      'status': status.name,
      'application_start_date': applicationStartDate?.toIso8601String(),
      'application_end_date': applicationEndDate?.toIso8601String(),
      'has_mains': hasMains ? 1 : 0,
      'has_skill_test': hasSkillTest ? 1 : 0,
      'has_interview': hasInterview ? 1 : 0,
      'has_dv': hasDV ? 1 : 0,
      'exam_date': examDate?.toIso8601String(),
      'mains_exam_date': mainsExamDate?.toIso8601String(),
      'skill_test_date': skillTestDate?.toIso8601String(),
      'interview_date': interviewDate?.toIso8601String(),
      'dv_date': dvDate?.toIso8601String(),
      'result_date': resultDate?.toIso8601String(),
      'phase_states': jsonEncode(phaseStates),
      'exam_pattern_data': jsonEncode(examPatternData),
      'syllabus_data': jsonEncode(syllabusData),
      'username_type': usernameType,
      'username': username,
      'password': password,
      'notes': notes,
      'additional_info': additionalInfo,
      'post_names': jsonEncode(postNames),
      'notification_pdf_path': notificationPdfPath,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedPhases = {};
    Map<String, dynamic> parsedPattern = {};
    Map<String, dynamic> parsedSyllabus = {};

    if (map['phase_states'] != null) {
      try { parsedPhases = Map<String, String>.from(jsonDecode(map['phase_states'])); } catch (_) {}
    }
    if (map['exam_pattern_data'] != null) {
      try { parsedPattern = Map<String, dynamic>.from(jsonDecode(map['exam_pattern_data'])); } catch (_) {}
    }
    if (map['syllabus_data'] != null) {
      try { parsedSyllabus = Map<String, dynamic>.from(jsonDecode(map['syllabus_data'])); } catch (_) {}
    }

    return ExamModel(
      id: map['id'] as String,
      examName: map['exam_name'] as String,
      advertisementNo: map['advertisement_no'] as String?,
      targetPost: map['target_post'] as String?,
      portalUrl: map['portal_url'] as String?,
      status: ApplicationStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => ApplicationStatus.notApplied),
      applicationStartDate: map['application_start_date'] != null ? DateTime.tryParse(map['application_start_date']) : null,
      applicationEndDate: map['application_end_date'] != null ? DateTime.tryParse(map['application_end_date']) : null,
      hasMains: map['has_mains'] == 1,
      hasSkillTest: map['has_skill_test'] == 1,
      hasInterview: map['has_interview'] == 1,
      hasDV: map['has_dv'] == 1,
      examDate: map['exam_date'] != null ? DateTime.tryParse(map['exam_date']) : null,
      mainsExamDate: map['mains_exam_date'] != null ? DateTime.tryParse(map['mains_exam_date']) : null,
      skillTestDate: map['skill_test_date'] != null ? DateTime.tryParse(map['skill_test_date']) : null,
      interviewDate: map['interview_date'] != null ? DateTime.tryParse(map['interview_date']) : null,
      dvDate: map['dv_date'] != null ? DateTime.tryParse(map['dv_date']) : null,
      resultDate: map['result_date'] != null ? DateTime.tryParse(map['result_date']) : null,
      phaseStates: parsedPhases,
      examPatternData: parsedPattern,
      syllabusData: parsedSyllabus,
      usernameType: map['username_type'] as String?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      notes: map['notes'] as String?,
      additionalInfo: map['additional_info'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ExamModel.fromJson(String source) => ExamModel.fromMap(jsonDecode(source));
}