import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'exam_status.dart';
export 'exam_status.dart';

class ExamModel {
  final String id;
  final String examName;
  final String? advertisementNo; // NEW FIELD
  final String? portalUrl;
  final ApplicationStatus status;
  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;
  final String? usernameType;
  final String? username;
  final String? password;
  final String? notes;
  final DateTime? examDate;
  final DateTime? mainsExamDate;
  final DateTime? resultDate;
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
    this.portalUrl,
    this.status = ApplicationStatus.notApplied,
    this.applicationStartDate,
    this.applicationEndDate,
    this.usernameType,
    this.username,
    this.password,
    this.notes,
    this.examDate,
    this.mainsExamDate,
    this.resultDate,
    this.additionalInfo,
    List<String>? postNames,
    this.notificationPdfPath,
    this.reminderEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        postNames = postNames ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ExamModel copyWith({
    String? id,
    String? examName,
    String? advertisementNo,
    String? portalUrl,
    ApplicationStatus? status,
    DateTime? applicationStartDate,
    DateTime? applicationEndDate,
    String? usernameType,
    String? username,
    String? password,
    String? notes,
    DateTime? examDate,
    DateTime? mainsExamDate,
    DateTime? resultDate,
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
      portalUrl: portalUrl ?? this.portalUrl,
      status: status ?? this.status,
      applicationStartDate: applicationStartDate ?? this.applicationStartDate,
      applicationEndDate: applicationEndDate ?? this.applicationEndDate,
      usernameType: usernameType ?? this.usernameType,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      examDate: examDate ?? this.examDate,
      mainsExamDate: mainsExamDate ?? this.mainsExamDate,
      resultDate: resultDate ?? this.resultDate,
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
      'portal_url': portalUrl,
      'status': status.name,
      'application_start_date': applicationStartDate?.toIso8601String(),
      'application_end_date': applicationEndDate?.toIso8601String(),
      'username_type': usernameType,
      'username': username,
      'password': password,
      'notes': notes,
      'exam_date': examDate?.toIso8601String(),
      'mains_exam_date': mainsExamDate?.toIso8601String(),
      'result_date': resultDate?.toIso8601String(),
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
    List<String> parsedPosts = [];
    if (map['post_names'] != null && map['post_names'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['post_names']);
        if (decoded is List) parsedPosts = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return ExamModel(
      id: map['id'] as String,
      examName: map['exam_name'] as String,
      advertisementNo: map['advertisement_no'] as String?,
      portalUrl: map['portal_url'] as String?,
      status: ApplicationStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => ApplicationStatus.notApplied,
      ),
      applicationStartDate: map['application_start_date'] != null ? DateTime.tryParse(map['application_start_date']) : null,
      applicationEndDate: map['application_end_date'] != null ? DateTime.tryParse(map['application_end_date']) : null,
      usernameType: map['username_type'] as String?,
      username: map['username'] as String?,
      password: map['password'] as String?,
      notes: map['notes'] as String?,
      examDate: map['exam_date'] != null ? DateTime.tryParse(map['exam_date']) : null,
      mainsExamDate: map['mains_exam_date'] != null ? DateTime.tryParse(map['mains_exam_date']) : null,
      resultDate: map['result_date'] != null ? DateTime.tryParse(map['result_date']) : null,
      additionalInfo: map['additional_info'] as String?,
      postNames: parsedPosts,
      notificationPdfPath: map['notification_pdf_path'] as String?,
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ExamModel.fromJson(String source) => ExamModel.fromMap(jsonDecode(source));
}