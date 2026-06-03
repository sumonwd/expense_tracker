import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static enc.Key _deriveKey(String passcode) {
    final bytes = utf8.encode(passcode);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static Uint8List encryptBytes(Uint8List data, String passcode) {
    final key = _deriveKey(passcode);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  static Uint8List decryptBytes(Uint8List encryptedData, String passcode) {
    if (encryptedData.length < 16) {
      throw Exception('Invalid encrypted data format');
    }
    
    final key = _deriveKey(passcode);
    final ivBytes = encryptedData.sublist(0, 16);
    final encryptedBytes = encryptedData.sublist(16);
    
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    try {
      final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed. Please verify that your passcode is correct.');
    }
  }
}
