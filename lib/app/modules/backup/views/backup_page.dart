import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/backup_controller.dart';
import '../../../core/widgets/glass_card.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BackupController backupController = Get.put(BackupController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Synchronization'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Obx(() {
                  final isSignedIn = backupController.isUserSignedIn.value;

                  return GlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white10 
                              : Colors.black.withOpacity(0.05),
                          backgroundImage: isSignedIn && backupController.userPhotoUrl.value.isNotEmpty
                              ? NetworkImage(backupController.userPhotoUrl.value)
                              : null,
                          child: !isSignedIn || backupController.userPhotoUrl.value.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSignedIn ? backupController.userDisplayName.value : 'Google Account',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSignedIn ? backupController.userEmail.value : 'Sign in to backup your data',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSignedIn ? Colors.red.shade900 : Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSignedIn ? backupController.signOut : backupController.signIn,
                          child: Text(
                            isSignedIn ? 'Sign Out' : 'Sign In',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                const Text(
                  'Cloud Backup (Google Drive)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Obx(() {
                  final isSignedIn = backupController.isUserSignedIn.value;
                  final meta = backupController.backupMetadata.value;

                  if (!isSignedIn) {
                    return const GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Please sign in to view cloud backup details.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }

                  final lastSync = meta != null && meta.createdTime != null
                      ? DateFormat('MMM dd, yyyy | hh:mm a').format(meta.createdTime!)
                      : 'Never';

                  final sizeKb = meta != null && meta.size != null
                      ? '${(int.parse(meta.size!) / 1024).toStringAsFixed(1)} KB'
                      : 'N/A';

                  return GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Last Synced', style: TextStyle(color: Colors.grey)),
                            Text(lastSync, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Backup Size', style: TextStyle(color: Colors.grey)),
                            Text(sizeKb, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                        const Text(
                          'Your backup is encrypted locally on your device with your password before being uploaded. No one (not even Google) can read it without your passcode.',
                          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                icon: const Icon(Icons.upload),
                                label: const Text('Backup Now'),
                                onPressed: () => _showPasscodeDialog(context, backupController, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.download, color: Colors.white),
                                label: const Text('Restore Backup', style: TextStyle(color: Colors.white)),
                                onPressed: () => _showPasscodeDialog(context, backupController, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Local JSON File Sync Section
                const Text(
                  'Local File Sync (Offline Backup)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildLocalJsonCard(context, backupController),
                const SizedBox(height: 40),
              ],
            ),
          ),

          Obx(() {
            if (backupController.isLoading.value) {
              return Container(
                color: Colors.black54,
                child: Center(
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          backupController.statusMessage.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildLocalJsonCard(BuildContext context, BackupController controller) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'JSON File Backup & Restore',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Export your complete expense data as a password-encrypted JSON file to store on your disk or share. You can import this file to restore your database anytime.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Export JSON'),
                  onPressed: () => _showLocalPasscodeDialog(context, controller, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  label: const Text('Import JSON', style: TextStyle(color: Colors.white)),
                  onPressed: () => _showLocalPasscodeDialog(context, controller, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPasscodeDialog(BuildContext context, BackupController controller, bool isBackup) {
    final TextEditingController textController = TextEditingController();
    final actionText = isBackup ? 'Encrypt & Backup' : 'Decrypt & Restore';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(actionText),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBackup
                    ? 'Enter a password to encrypt this backup. You will need this same password to restore the backup on any device.'
                    : 'Enter the password that was used to encrypt this backup.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Backup Passcode',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final passcode = textController.text.trim();
                Navigator.pop(context);
                if (isBackup) {
                  controller.backupData(passcode);
                } else {
                  controller.restoreData(passcode);
                }
              },
              child: Text(isBackup ? 'Backup' : 'Restore'),
            ),
          ],
        );
      },
    );
  }

  void _showLocalPasscodeDialog(BuildContext context, BackupController controller, bool isExport) {
    final TextEditingController textController = TextEditingController();
    final actionText = isExport ? 'Encrypt & Export File' : 'Decrypt & Import File';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(actionText),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExport
                    ? 'Enter a password to encrypt this JSON backup. Keep this password safe as you will need it to restore your data.'
                    : 'Enter the password that was used to encrypt this backup file.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Backup Passcode',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final passcode = textController.text.trim();
                Navigator.pop(context);
                if (isExport) {
                  controller.exportJsonBackup(passcode);
                } else {
                  controller.importJsonBackup(passcode);
                }
              },
              child: Text(isExport ? 'Export' : 'Import'),
            ),
          ],
        );
      },
    );
  }
}
