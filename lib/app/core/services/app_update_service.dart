import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isUpdateAvailable;

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });
}

class AppUpdateService {
  static const String _repoOwner = 'sumonwd';
  static const String _repoName = 'expense_tracker';

  /// Check the GitHub Releases API for the latest release
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? 'No release notes.';
      final assets = data['assets'] as List<dynamic>? ?? [];

      // Find the APK asset
      String downloadUrl = '';
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }

      if (downloadUrl.isEmpty || tagName.isEmpty) return null;

      // Compare versions
      final latestVersion = tagName.replaceFirst('v', '');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final isNewer = _isVersionNewer(latestVersion, currentVersion);

      return AppUpdateInfo(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: body,
        isUpdateAvailable: isNewer,
      );
    } catch (e) {
      // Silently fail — don't block the app if update check fails
      return null;
    }
  }

  /// Download APK to temporary directory with progress callback
  Future<String?> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) return null;

      final contentLength = streamedResponse.contentLength ?? 0;
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/expense_tracker_update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      int downloaded = 0;

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength > 0) {
          onProgress(downloaded / contentLength);
        }
      }

      await sink.close();
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Open the downloaded APK to trigger Android's package installer
  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  /// Compare two semantic version strings (e.g. "1.2.0" > "1.1.0")
  bool _isVersionNewer(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to 3 parts
    while (latestParts.length < 3) latestParts.add(0);
    while (currentParts.length < 3) currentParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    return false; // Same version
  }
}
