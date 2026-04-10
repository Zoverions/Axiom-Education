import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  group('Security Fix: AES-GCM Authenticated Encryption', () {
    final key = encrypt.Key.fromUtf8('my_secret_key_32_chars_long_1234');

    test('GCM decryption fails if ciphertext is tampered', () {
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final iv = encrypt.IV.fromSecureRandom(12);

      final plainText = '{"type": "CANVAS_SYNC", "strokes": []}';
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final corruptedBytes = Uint8List.fromList(encrypted.bytes);
      // Flip a bit in the ciphertext or authentication tag
      corruptedBytes[0] ^= 0x01;

      final corruptedEncrypted = encrypt.Encrypted(corruptedBytes);

      // Decryption should throw an exception because of the integrity check
      expect(() => encrypter.decrypt(corruptedEncrypted, iv: iv), throwsException);
    });

    test('GCM decryption succeeds if not tampered', () {
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final iv = encrypt.IV.fromSecureRandom(12);

      final plainText = '{"type": "CANVAS_SYNC", "strokes": []}';
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      expect(decrypted, equals(plainText));
    });
  });
}
