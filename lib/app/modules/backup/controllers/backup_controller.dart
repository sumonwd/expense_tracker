import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/google_drive_service.dart';
import '../../dashboard/controllers/transaction_controller.dart';
import '../../budget/controllers/budget_controller.dart';

class BackupController extends GetxController {
  final GoogleDriveService _driveService = GoogleDriveService();
  final DBHelper _dbHelper = DBHelper();

  var isUserSignedIn = false.obs;
  var userEmail = ''.obs;
  var userDisplayName = ''.obs;
  var userPhotoUrl = ''.obs;

  var backupMetadata = Rxn<drive.File>();
  var isLoading = false.obs;
  var statusMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkSignInSilently();
  }

  Future<void> _checkSignInSilently() async {
    isLoading.value = true;
    statusMessage.value = 'Checking Google Sign-in state...';
    try {
      final account = await _driveService.signInSilently();
      _updateSignInState(account);
      if (account != null) {
        await fetchBackupMetadata();
      }
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  Future<void> signIn() async {
    isLoading.value = true;
    statusMessage.value = 'Signing in to Google...';
    try {
      final account = await _driveService.signIn();
      _updateSignInState(account);
      if (account != null) {
        await fetchBackupMetadata();
      }
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    statusMessage.value = 'Signing out...';
    try {
      await _driveService.signOut();
      _updateSignInState(null);
      backupMetadata.value = null;
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  void _updateSignInState(dynamic account) {
    if (account != null) {
      isUserSignedIn.value = true;
      userEmail.value = account.email;
      userDisplayName.value = account.displayName ?? '';
      userPhotoUrl.value = account.photoUrl ?? '';
    } else {
      isUserSignedIn.value = false;
      userEmail.value = '';
      userDisplayName.value = '';
      userPhotoUrl.value = '';
    }
  }

  Future<void> fetchBackupMetadata() async {
    try {
      final meta = await _driveService.getBackupMetadata();
      backupMetadata.value = meta;
    } catch (e) {
      print('Error fetching metadata: $e');
    }
  }

  // --- Google Drive Backup / Restore (SQLite File Binary) ---

  Future<bool> backupData(String passcode) async {
    if (passcode.isEmpty) {
      Get.snackbar('Error', 'Please enter a passcode for backup encryption.');
      return false;
    }

    isLoading.value = true;
    statusMessage.value = 'Encrypting database and uploading...';

    try {
      String dbPath = p.join(await getDatabasesPath(), 'expense_tracker.db');
      File dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        Get.snackbar('Error', 'Local database file not found.');
        return false;
      }

      await _dbHelper.closeDb();

      Uint8List dbBytes = await dbFile.readAsBytes();
      Uint8List encryptedBytes = EncryptionService.encryptBytes(dbBytes, passcode);

      String tempPath = p.join(Directory.systemTemp.path, 'backup.enc');
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(encryptedBytes);

      final desc = 'Encrypted Backup | Timestamp: ${DateTime.now().toIso8601String()}';
      await _driveService.uploadBackup(tempFile, description: desc);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await fetchBackupMetadata();

      Get.snackbar('Success', 'Backup completed and uploaded successfully!');
      return true;
    } catch (e) {
      Get.snackbar('Backup Error', 'An error occurred during backup: $e');
      return false;
    } finally {
      await _dbHelper.database;
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  Future<bool> restoreData(String passcode) async {
    if (passcode.isEmpty) {
      Get.snackbar('Error', 'Please enter your passcode to decrypt the backup.');
      return false;
    }

    isLoading.value = true;
    statusMessage.value = 'Downloading and decrypting backup...';

    try {
      String tempPath = p.join(Directory.systemTemp.path, 'restore.enc');
      File tempFile = File(tempPath);

      final downloadedFile = await _driveService.downloadBackup(tempFile);
      if (downloadedFile == null) {
        Get.snackbar('No Backup', 'No backup was found on Google Drive.');
        return false;
      }

      Uint8List encryptedBytes = await downloadedFile.readAsBytes();
      Uint8List decryptedBytes = EncryptionService.decryptBytes(encryptedBytes, passcode);

      await _dbHelper.closeDb();

      String dbPath = p.join(await getDatabasesPath(), 'expense_tracker.db');
      File dbFile = File(dbPath);
      await dbFile.writeAsBytes(decryptedBytes);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final txController = Get.find<TransactionController>();
      await txController.loadAllData();

      final budgetController = Get.find<BudgetController>();
      await budgetController.loadBudgetData();

      Get.snackbar('Success', 'Database restored and synchronized successfully!');
      return true;
    } catch (e) {
      Get.snackbar('Restore Error', e.toString());
      return false;
    } finally {
      await _dbHelper.database;
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  // --- Offline JSON File Backup / Restore ---

  Future<bool> exportJsonBackup(String passcode) async {
    if (passcode.isEmpty) {
      Get.snackbar('Error', 'Please enter a passcode for backup encryption.');
      return false;
    }

    isLoading.value = true;
    statusMessage.value = 'Generating encrypted JSON backup...';

    try {
      final db = await _dbHelper.database;

      final wallets = await db.query('wallets');
      final categories = await db.query('categories');
      final transactions = await db.query('transactions');
      final budgets = await db.query('budgets');

      final Map<String, dynamic> backupMap = {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'wallets': wallets,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
      };

      final jsonString = jsonEncode(backupMap);
      final utf8Bytes = utf8.encode(jsonString);
      final encryptedBytes = EncryptionService.encryptBytes(
        Uint8List.fromList(utf8Bytes),
        passcode,
      );

      // Save directly to files using the native save dialog.
      // The `bytes` parameter ensures the plugin writes the data on all platforms.
      statusMessage.value = 'Choose save location...';
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'expense_tracker_backup.json',
        bytes: Uint8List.fromList(encryptedBytes),
      );

      if (savedPath != null) {
        Get.snackbar('Success', 'Backup saved successfully!');
      } else {
        Get.snackbar('Cancelled', 'Backup file was not saved.');
        return false;
      }

      return true;
    } catch (e) {
      Get.snackbar('Export Error', 'Failed to generate local backup file: $e');
      return false;
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  Future<bool> importJsonBackup(String passcode) async {
    if (passcode.isEmpty) {
      Get.snackbar('Error', 'Please enter your passcode to decrypt the backup file.');
      return false;
    }

    isLoading.value = true;
    statusMessage.value = 'Opening file selector...';

    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result == null || result.files.single.path == null) {
        Get.snackbar('Cancelled', 'No file was selected.');
        return false;
      }

      statusMessage.value = 'Reading and decrypting file...';
      final file = File(result.files.single.path!);
      final encryptedBytes = await file.readAsBytes();

      final decryptedBytes = EncryptionService.decryptBytes(encryptedBytes, passcode);
      final jsonString = utf8.decode(decryptedBytes);

      final Map<String, dynamic> backupMap = jsonDecode(jsonString);
      if (!backupMap.containsKey('version') || !backupMap.containsKey('transactions')) {
        Get.snackbar('Error', 'Invalid backup file format.');
        return false;
      }

      statusMessage.value = 'Restoring database records...';

      final walletsList = backupMap['wallets'] as List<dynamic>? ?? [];
      final categoriesList = backupMap['categories'] as List<dynamic>? ?? [];
      final transactionsList = backupMap['transactions'] as List<dynamic>? ?? [];
      final budgetsList = backupMap['budgets'] as List<dynamic>? ?? [];

      await _dbHelper.closeDb();
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('budgets');
        await txn.delete('categories');
        await txn.delete('wallets');

        for (var w in walletsList) {
          await txn.insert('wallets', {
            'id': w['id'],
            'name': w['name'],
            'color_value': w['color_value'],
            'icon_code': w['icon_code'],
          });
        }

        for (var c in categoriesList) {
          await txn.insert('categories', {
            'id': c['id'],
            'name': c['name'],
            'type': c['type'],
            'icon_code': c['icon_code'],
            'color_value': c['color_value'],
            'is_system': c['is_system'] ?? 0,
          });
        }

        for (var t in transactionsList) {
          await txn.insert('transactions', {
            'id': t['id'],
            'amount': t['amount'],
            'type': t['type'],
            'category_id': t['category_id'],
            'wallet_id': t['wallet_id'],
            'transfer_wallet_id': t['transfer_wallet_id'],
            'date': t['date'],
            'note': t['note'],
          });
        }

        for (var b in budgetsList) {
          await txn.insert('budgets', {
            'id': b['id'],
            'category_id': b['category_id'],
            'amount': b['amount'],
            'month': b['month'],
          });
        }
      });

      if (Get.isRegistered<TransactionController>()) {
        final txController = Get.find<TransactionController>();
        await txController.loadAllData();
      }

      if (Get.isRegistered<BudgetController>()) {
        final budgetController = Get.find<BudgetController>();
        await budgetController.loadBudgetData();
      }

      Get.snackbar('Success', 'Local backup file successfully restored!');
      return true;
    } catch (e) {
      Get.snackbar('Restore Error', 'Decryption or database restore failed: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }
}
