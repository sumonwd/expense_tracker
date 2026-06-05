import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  static const List<String> _driveScopes = [drive.DriveApi.driveAppdataScope];

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize(
        // Use the "Web application" type OAuth Client ID (not Android)
        serverClientId: '241691454409-647invdoqk4oocdqre516bc8ifh44p35.apps.googleusercontent.com',
      );
      _initialized = true;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      await _ensureInitialized();
      _currentUser = await _googleSignIn.authenticate();
      return _currentUser;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      await _ensureInitialized();
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      return _currentUser;
    } catch (e) {
      print('Google Silent Sign-In Error: $e');
      return null;
    }
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    final account = _currentUser ?? await signInSilently();
    if (account == null) return null;

    // Request authorization for Drive scopes and get an access token.
    final authorization = await account.authorizationClient.authorizeScopes(_driveScopes);
    final accessToken = authorization.accessToken;

    final authenticateClient = GoogleAuthClient({'Authorization': 'Bearer $accessToken'});
    return drive.DriveApi(authenticateClient);
  }

  Future<drive.File?> uploadBackup(File file, {String? description}) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('User is not signed in to Google.');

    final existingFile = await _findBackupFile(driveApi);

    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File();
    driveFile.name = 'expense_tracker_backup.enc';
    driveFile.description = description ?? 'Encrypted Personal Expense Tracker Backup';

    if (existingFile != null && existingFile.id != null) {
      return await driveApi.files.update(driveFile, existingFile.id!, uploadMedia: media);
    } else {
      driveFile.parents = ['appDataFolder'];
      return await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  Future<File?> downloadBackup(File destinationFile) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) throw Exception('User is not signed in to Google.');

    final existingFile = await _findBackupFile(driveApi);
    if (existingFile == null || existingFile.id == null) {
      return null;
    }

    final mediaResponse =
        await driveApi.files.get(existingFile.id!, downloadOptions: drive.DownloadOptions.fullMedia)
            as drive.Media;

    final List<int> dataBytes = [];
    await for (final chunk in mediaResponse.stream) {
      dataBytes.addAll(chunk);
    }
    await destinationFile.writeAsBytes(dataBytes);
    return destinationFile;
  }

  Future<drive.File?> getBackupMetadata() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;
    return await _findBackupFile(driveApi);
  }

  Future<drive.File?> _findBackupFile(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(
      q: "name = 'expense_tracker_backup.enc'",
      spaces: 'appDataFolder',
      $fields: 'files(id, name, createdTime, description, size)',
    );
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first;
    }
    return null;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
