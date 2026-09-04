import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../data/models/exam_model.dart';
import 'google_auth_client.dart';

class DriveSyncService {
  static const String _backupFileName = 'govt_exams_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async => await _googleSignIn.signIn();

  // NEW: Silent Sign-In restores the session when app opens from closed state
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async => await _googleSignIn.signOut();

  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _googleSignIn.currentUser ?? await signInSilently();
    if (account == null) return null;
    final authHeaders = await account.authHeaders;
    return drive.DriveApi(GoogleAuthClient(authHeaders));
  }

  Future<String?> _getBackupFileId(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(spaces: 'appDataFolder', q: "name = '$_backupFileName'");
    return fileList.files?.isNotEmpty == true ? fileList.files!.first.id : null;
  }

  Future<bool> backupData(List<ExamModel> exams, String? groqApiKey) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final fileId = await _getBackupFileId(driveApi);

      final Map<String, dynamic> payload = {
        'api_key': groqApiKey,
        'exams': exams.map((e) => e.toMap()).toList(),
      };

      final String jsonData = jsonEncode(payload);
      final media = drive.Media(Stream.value(utf8.encode(jsonData)), utf8.encode(jsonData).length);

      if (fileId == null) {
        final fileToUpload = drive.File()..name = _backupFileName..parents = ['appDataFolder'];
        await driveApi.files.create(fileToUpload, uploadMedia: media);
      } else {
        final fileToUpdate = drive.File()..name = _backupFileName;
        await driveApi.files.update(fileToUpdate, fileId, uploadMedia: media);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> restoreData() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final fileId = await _getBackupFileId(driveApi);
      if (fileId == null) return {'exams': <ExamModel>[], 'api_key': null};

      final response = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = await response.stream.expand((x) => x).toList();
      final String jsonStr = utf8.decode(bytes);

      final dynamic decoded = jsonDecode(jsonStr);

      if (decoded is List) {
        return {
          'exams': decoded.map((e) => ExamModel.fromMap(e)).toList(),
          'api_key': null,
        };
      }
      else if (decoded is Map<String, dynamic>) {
        return {
          'exams': (decoded['exams'] as List).map((e) => ExamModel.fromMap(e)).toList(),
          'api_key': decoded['api_key'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}