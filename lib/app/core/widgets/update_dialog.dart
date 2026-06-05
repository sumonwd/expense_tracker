import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/update_controller.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  static void show() {
    final updateController = Get.find<UpdateController>();

    ever(updateController.status, (status) {
      if (status == UpdateStatus.available) {
        Get.dialog(
          const UpdateDialog(),
          barrierDismissible: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateController = Get.find<UpdateController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Obx(() {
          final status = updateController.status.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                status == UpdateStatus.downloaded
                    ? 'Ready to Install!'
                    : 'Update Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Version info
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final currentVersion = snapshot.data?.version ?? '...';
                  return Text(
                    'v$currentVersion → v${updateController.latestVersion.value}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Release notes
              if (status == UpdateStatus.available ||
                  status == UpdateStatus.downloading ||
                  status == UpdateStatus.downloaded)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateController.releaseNotes.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

              // Download progress
              if (status == UpdateStatus.downloading) ...[
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: updateController.downloadProgress.value,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D9488),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(updateController.downloadProgress.value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],

              // Error message
              if (status == UpdateStatus.error) ...[
                const SizedBox(height: 12),
                Text(
                  updateController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              if (status == UpdateStatus.available)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          updateController.dismiss();
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => updateController.startDownload(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

              if (status == UpdateStatus.downloading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Downloading...'),
                  ),
                ),

              if (status == UpdateStatus.downloaded)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => updateController.installUpdate(),
                    icon: const Icon(Icons.install_mobile_rounded),
                    label: const Text(
                      'Install Update',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

              if (status == UpdateStatus.error)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          updateController.dismiss();
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateController.startDownload(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }
}
