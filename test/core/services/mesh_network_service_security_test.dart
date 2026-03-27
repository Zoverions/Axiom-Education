import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  group('Encryption Security Analysis', () {
    test('Vulnerability: AES in SIC (CTR) mode is malleable (Current state)', () {
      final key = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);
      // This matches the current vulnerable implementation in MeshNetworkService
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final original = '{"type":"CANVAS_SYNC","strokes":[]}';
      final encrypted = encrypter.encrypt(original, iv: iv);

      final tamperedBytes = Uint8List.fromList(encrypted.bytes);
      // Tamper with the ciphertext (flip a bit)
      tamperedBytes[tamperedBytes.length - 1] ^= 0x01;
      final tamperedEncrypted = encrypt.Encrypted(tamperedBytes);

      // In SIC/CTR mode, decryption succeeds but produces corrupted data
      // This is the core of the malleability vulnerability.
      final decrypted = encrypter.decrypt(tamperedEncrypted, iv: iv);
      expect(decrypted, isNot(equals(original)));
      // It did NOT throw an exception, which is the problem.
    });

    test('Verification: AES in GCM mode provides integrity (Desired state)', () {
      final key = encrypt.Key.fromSecureRandom(32);
      final iv = encrypt.IV.fromSecureRandom(16);
      // This is the proposed fix
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

      final original = '{"type":"CANVAS_SYNC","strokes":[]}';
      final encrypted = encrypter.encrypt(original, iv: iv);

      final tamperedBytes = Uint8List.fromList(encrypted.bytes);
      tamperedBytes[tamperedBytes.length - 1] ^= 0x01;
      final tamperedEncrypted = encrypt.Encrypted(tamperedBytes);

      // In GCM mode, decryption MUST throw an exception if the ciphertext or MAC is tampered with.
      expect(() => encrypter.decrypt(tamperedEncrypted, iv: iv), throwsA(anything));
    });
  });
}
