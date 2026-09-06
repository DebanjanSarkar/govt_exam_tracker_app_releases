import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/drive_sync_service.dart';
import '../data/models/exam_model.dart';
import '../core/constants/app_constants.dart';
import 'exam_provider.dart';
import 'ai_cooldown_provider.dart';

final driveSyncServiceProvider = Provider((ref) => DriveSyncService());

class SyncState {
  final bool isLoading;
  final String? error;
  final GoogleSignInAccount? account;
  final String? lastSyncMessage;

  SyncState({this.isLoading = false, this.error, this.account, this.lastSyncMessage});

  SyncState copyWith({bool? isLoading, String? error, GoogleSignInAccount? account, String? lastSyncMessage}) {
    return SyncState(isLoading: isLoading ?? this.isLoading, error: error, account: account ?? this.account, lastSyncMessage: lastSyncMessage);
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final DriveSyncService _syncService;
  final Ref _ref;

  SyncNotifier(this._syncService, this._ref) : super(SyncState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final account = await _syncService.signInSilently();
      if (account != null) {
        state = state.copyWith(account: account);
        await pullFromDrive();
      }
    } catch (e) {}
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, error: null);
    final account = await _syncService.signIn();
    if (account != null) {
      state = state.copyWith(isLoading: false, account: account, lastSyncMessage: 'Logged in successfully');
      await pullFromDrive();
    } else {
      state = state.copyWith(isLoading: false, error: 'Sign in cancelled');
    }
  }

  Future<void> logout() async {
    await _syncService.signOut();
    state = SyncState();
  }

  Future<void> pushToDrive() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = _ref.read(examRepositoryProvider);
    final localExams = await repository.getAllExams();

    final prefs = _ref.read(sharedPreferencesProvider);
    final aiSettings = {
      'gemini_key': prefs.getString(AppConstants.prefsGeminiApiKey),
      'groq_key': prefs.getString(AppConstants.prefsGroqApiKey),
      'active_provider': prefs.getString(AppConstants.prefsActiveAiProvider) ?? 'groq',
    };

    final success = await _syncService.backupData(localExams, aiSettings);

    if (success) state = state.copyWith(isLoading: false, lastSyncMessage: 'Backup successful');
    else state = state.copyWith(isLoading: false, error: 'Backup failed');
  }

  Future<void> pullFromDrive() async {
    state = state.copyWith(isLoading: true, error: null);

    final remoteData = await _syncService.restoreData();
    if (remoteData == null) {
      state = state.copyWith(isLoading: false, error: 'Failed to fetch data');
      return;
    }

    // SYNC AI SETTINGS
    final remoteAiSettings = remoteData['ai_settings'] as Map<String, dynamic>?;
    final prefs = _ref.read(sharedPreferencesProvider);

    if (remoteAiSettings != null) {
      final localGemini = prefs.getString(AppConstants.prefsGeminiApiKey);
      final localGroq = prefs.getString(AppConstants.prefsGroqApiKey);

      if ((localGemini == null || localGemini.isEmpty) && remoteAiSettings['gemini_key'] != null) {
        await prefs.setString(AppConstants.prefsGeminiApiKey, remoteAiSettings['gemini_key']);
      }
      if ((localGroq == null || localGroq.isEmpty) && remoteAiSettings['groq_key'] != null) {
        await prefs.setString(AppConstants.prefsGroqApiKey, remoteAiSettings['groq_key']);
      }
      if (remoteAiSettings['active_provider'] != null) {
        await prefs.setString(AppConstants.prefsActiveAiProvider, remoteAiSettings['active_provider']);
      }
    }

    final remoteExams = remoteData['exams'] as List<ExamModel>;
    if (remoteExams.isEmpty) {
      state = state.copyWith(isLoading: false, lastSyncMessage: 'No backup found');
      return;
    }

    final repository = _ref.read(examRepositoryProvider);
    final localExams = await repository.getAllExams();
    final localMap = {for (var e in localExams) e.id: e};

    List<ExamModel> toUpdate = [];
    for (var remote in remoteExams) {
      final local = localMap[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        toUpdate.add(remote);
      }
    }

    if (toUpdate.isNotEmpty) {
      await repository.bulkSyncInsert(toUpdate);
      await _ref.read(examListProvider.notifier).loadExams();
      state = state.copyWith(isLoading: false, lastSyncMessage: 'Synced ${toUpdate.length} records');
    } else {
      state = state.copyWith(isLoading: false, lastSyncMessage: 'Already up to date');
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier(ref.watch(driveSyncServiceProvider), ref));