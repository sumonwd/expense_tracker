import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/app/core/services/encryption_service.dart';

void main() {
  group('AES-256 Encryption Tests', () {
    test('Encrypting and decrypting data yields identical bytes', () {
      const originalString = 'Hello, this is a secure database backup file content!';
      final originalBytes = Uint8List.fromList(originalString.codeUnits);
      const passcode = 'superSecretPasscode123';

      final encrypted = EncryptionService.encryptBytes(originalBytes, passcode);
      expect(encrypted, isNotNull);
      expect(encrypted.length, greaterThan(16)); // 16-byte IV + ciphertext

      final decrypted = EncryptionService.decryptBytes(encrypted, passcode);
      final decryptedString = String.fromCharCodes(decrypted);

      expect(decryptedString, equals(originalString));
    });

    test('Decryption with incorrect passcode throws an exception', () {
      final originalBytes = Uint8List.fromList('Sensitive Data'.codeUnits);
      const passcode = 'pass123';
      const wrongPasscode = 'pass456';

      final encrypted = EncryptionService.encryptBytes(originalBytes, passcode);
      
      expect(
        () => EncryptionService.decryptBytes(encrypted, wrongPasscode),
        throwsException,
      );
    });
  });
}
