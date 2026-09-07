import 'dart:convert';
import 'package:uuid/uuid.dart';

class ReminderModel {
  final String id;
  final String examId;
  final String examName;
  final String title;
  final String? description;
  final DateTime time;

  final String repeatType;
  final int interval;
  final String frequency;
  final List<int> weekdays;

  final String endType;
  final DateTime? endDate;
  final String? endPhase;

  final bool isActive;
  final bool isHighPriority; // NEW FIELD
  final DateTime createdAt;

  ReminderModel({
    String? id,
    required this.examId,
    required this.examName,
    required this.title,
    this.description,
    required this.time,
    this.repeatType = 'none',
    this.interval = 1,
    this.frequency = 'day',
    List<int>? weekdays,
    this.endType = 'never',
    this.endDate,
    this.endPhase,
    this.isActive = true,
    this.isHighPriority = false, // Defaults to false
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        weekdays = weekdays ?? [],
        createdAt = createdAt ?? DateTime.now();

  ReminderModel copyWith({
    String? id,
    String? examId,
    String? examName,
    String? title,
    String? description,
    DateTime? time,
    String? repeatType,
    int? interval,
    String? frequency,
    List<int>? weekdays,
    String? endType,
    DateTime? endDate,
    String? endPhase,
    bool? isActive,
    bool? isHighPriority,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      repeatType: repeatType ?? this.repeatType,
      interval: interval ?? this.interval,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      endType: endType ?? this.endType,
      endDate: endDate ?? this.endDate,
      endPhase: endPhase ?? this.endPhase,
      isActive: isActive ?? this.isActive,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'exam_name': examName,
      'title': title,
      'description': description,
      'time': time.toIso8601String(),
      'repeat_type': repeatType,
      'interval': interval,
      'frequency': frequency,
      'weekdays': jsonEncode(weekdays),
      'end_type': endType,
      'end_date': endDate?.toIso8601String(),
      'end_phase': endPhase,
      'is_active': isActive ? 1 : 0,
      'is_high_priority': isHighPriority ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      examId: map['exam_id'],
      examName: map['exam_name'],
      title: map['title'],
      description: map['description'],
      time: DateTime.parse(map['time']),
      repeatType: map['repeat_type'] ?? 'none',
      interval: map['interval'] ?? 1,
      frequency: map['frequency'] ?? 'day',
      weekdays: List<int>.from(jsonDecode(map['weekdays'] ?? '[]')),
      endType: map['end_type'] ?? 'never',
      endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date']) : null,
      endPhase: map['end_phase'],
      isActive: map['is_active'] == 1,
      isHighPriority: map['is_high_priority'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}