import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/exam_repository.dart';
import '../data/models/exam_model.dart';
import '../core/services/notification_service.dart';
import 'ai_cooldown_provider.dart'; // We use the injected sharedPreferencesProvider

// --- ENUMS FOR SORTING ---
enum SortField { applicationCloseDate, examDate }
enum SortOrder { newerFirst, olderFirst }

// --- REPOSITORY & BASE LIST ---
final examRepositoryProvider = Provider<ExamRepository>((ref) => ExamRepository());

class ExamListNotifier extends StateNotifier<AsyncValue<List<ExamModel>>> {
  final ExamRepository _repository;
  ExamListNotifier(this._repository) : super(const AsyncValue.loading()) { loadExams(); }

  Future<void> loadExams() async {
    state = const AsyncValue.loading();
    try {
      final exams = await _repository.getAllExams();
      for (var exam in exams) { NotificationService.scheduleExamReminders(exam); }
      state = AsyncValue.data(exams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExam(ExamModel exam) async {
    await _repository.insertExam(exam);
    await NotificationService.scheduleExamReminders(exam);
    await loadExams();
  }

  Future<void> updateExam(ExamModel exam) async {
    await _repository.updateExam(exam);
    await NotificationService.scheduleExamReminders(exam);
    await loadExams();
  }

  Future<void> deleteExam(String id) async {
    await _repository.softDeleteExam(id);
    await NotificationService.cancelExamReminders(id);
    await loadExams();
  }
}

final examListProvider = StateNotifierProvider<ExamListNotifier, AsyncValue<List<ExamModel>>>((ref) {
  return ExamListNotifier(ref.watch(examRepositoryProvider));
});


// --- PERSISTENT YEAR FILTER NOTIFIER ---
class YearFilterNotifier extends StateNotifier<int?> {
  final SharedPreferences _prefs;
  static const String _yearKey = 'selected_filter_year';

  YearFilterNotifier(this._prefs) : super(null) {
    // Load from RAM-cleared persistence on startup
    final savedYear = _prefs.getInt(_yearKey);
    if (savedYear != 0) state = savedYear;
  }

  void setYear(int? year) {
    state = year;
    if (year == null) {
      _prefs.remove(_yearKey);
    } else {
      _prefs.setInt(_yearKey, year);
    }
  }
}

final yearFilterProvider = StateNotifierProvider<YearFilterNotifier, int?>((ref) {
  return YearFilterNotifier(ref.watch(sharedPreferencesProvider));
});


// --- OTHER FILTER & SORT STATES ---
final searchQueryProvider = StateProvider<String>((ref) => '');
final statusFilterProvider = StateProvider<ApplicationStatus?>((ref) => null);

// Default Sort: Application Close Date, Newer First
final sortFieldProvider = StateProvider<SortField>((ref) => SortField.applicationCloseDate);
final sortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.newerFirst);
final showNullDatesProvider = StateProvider<bool>((ref) => true);


// --- THE MASTER FILTER & SORT COMPUTATION ENGINE ---
final filteredExamsProvider = Provider<AsyncValue<List<ExamModel>>>((ref) {
  final examsState = ref.watch(examListProvider);

  final query = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);
  final yearFilter = ref.watch(yearFilterProvider);

  final sortField = ref.watch(sortFieldProvider);
  final sortOrder = ref.watch(sortOrderProvider);
  final showNullDates = ref.watch(showNullDatesProvider);

  return examsState.whenData((exams) {
    // 1. FILTERING
    var filtered = exams.where((exam) {
      // Search
      final matchesQuery = query.isEmpty ||
          exam.examName.toLowerCase().contains(query) ||
          (exam.advertisementNo?.toLowerCase().contains(query) ?? false) ||
          (exam.notes?.toLowerCase().contains(query) ?? false);

      // Status
      final matchesStatus = statusFilter == null || exam.status == statusFilter;

      // Persistent Year
      final matchesYear = yearFilter == null ||
          (exam.applicationEndDate?.year == yearFilter);

      // Hide Nulls (if user toggled it off)
      bool matchesNullPolicy = true;
      if (!showNullDates) {
        if (sortField == SortField.examDate && exam.examDate == null) matchesNullPolicy = false;
        if (sortField == SortField.applicationCloseDate && exam.applicationEndDate == null) matchesNullPolicy = false;
      }

      return matchesQuery && matchesStatus && matchesYear && matchesNullPolicy;
    }).toList();

    // 2. SORTING ALGORITHM (Highly Optimized)
    filtered.sort((a, b) {
      DateTime? dateA = sortField == SortField.examDate ? a.examDate : a.applicationEndDate;
      DateTime? dateB = sortField == SortField.examDate ? b.examDate : b.applicationEndDate;

      // Always push Null dates to the very bottom regardless of asc/desc to keep UI clean
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      // Ascending (Older First) vs Descending (Newer First)
      if (sortOrder == SortOrder.newerFirst) {
        return dateB.compareTo(dateA);
      } else {
        return dateA.compareTo(dateB);
      }
    });

    return filtered;
  });
});