import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/app_update_service.dart';

enum UpdateStatus { idle, checking, available, downloading, downloaded, error }

class UpdateController extends GetxController {
  final AppUpdateService _updateService = AppUpdateService();

  final Rx<UpdateStatus> status = UpdateStatus.idle.obs;
  final RxString latestVersion = ''.obs;
  final RxString releaseNotes = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString errorMessage = ''.obs;

  String _downloadUrl = '';
  String? _downloadedFilePath;

  @override
  void onInit() {
    super.onInit();
    // Check for updates 3 seconds after app starts
    Future.delayed(const Duration(seconds: 3), () => checkForUpdate());
  }

  Future<void> checkForUpdate() async {
    status.value = UpdateStatus.checking;

    final updateInfo = await _updateService.checkForUpdate();

    if (updateInfo == null) {
      status.value = UpdateStatus.idle;
      return;
    }

    if (updateInfo.isUpdateAvailable) {
      latestVersion.value = updateInfo.latestVersion;
      releaseNotes.value = updateInfo.releaseNotes;
      _downloadUrl = updateInfo.downloadUrl;
      status.value = UpdateStatus.available;
    } else {
      status.value = UpdateStatus.idle;
    }
  }

  Future<void> startDownload() async {
    if (_downloadUrl.isEmpty) return;

    status.value = UpdateStatus.downloading;
    downloadProgress.value = 0.0;

    final filePath = await _updateService.downloadApk(
      _downloadUrl,
      (progress) {
        downloadProgress.value = progress;
      },
    );

    if (filePath != null) {
      _downloadedFilePath = filePath;
      status.value = UpdateStatus.downloaded;
    } else {
      errorMessage.value = 'Failed to download update. Please try again.';
      status.value = UpdateStatus.error;
    }
  }

  Future<void> installUpdate() async {
    if (_downloadedFilePath == null) return;

    // Request install permission on Android
    final installStatus = await Permission.requestInstallPackages.request();
    if (!installStatus.isGranted) {
      errorMessage.value = 'Install permission is required to update the app.';
      status.value = UpdateStatus.error;
      return;
    }

    final success = await _updateService.installApk(_downloadedFilePath!);
    if (!success) {
      errorMessage.value = 'Failed to open the installer. Please try again.';
      status.value = UpdateStatus.error;
    }
  }

  void dismiss() {
    status.value = UpdateStatus.idle;
  }
}
