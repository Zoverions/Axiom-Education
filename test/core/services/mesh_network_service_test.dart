import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

void main() {
  group('MeshNetworkService Authentication', () {
    test('generateDiscoveryPayload produces valid JSON with correct structure', () {
      final service = MeshNetworkService(classroomPin: 'test_pin');
      final payloadJson = service.generateDiscoveryPayload();

      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      expect(payload.containsKey('msg'), isTrue);
      expect(payload['msg'], equals('TEACHER_NODE_HERE'));
      expect(payload.containsKey('timestamp'), isTrue);
      expect(payload['timestamp'], isA<int>());
      expect(payload.containsKey('signature'), isTrue);
      expect(payload['signature'], isA<String>());
    });

    test('verifyDiscoveryPayload returns true for valid payload with correct PIN', () {
      final teacherService = MeshNetworkService(classroomPin: 'secret_classroom_123');
      final studentService = MeshNetworkService(classroomPin: 'secret_classroom_123');

      final payloadJson = teacherService.generateDiscoveryPayload();

      final isValid = studentService.verifyDiscoveryPayload(payloadJson);
      expect(isValid, isTrue);
    });

    test('verifyDiscoveryPayload returns false for valid payload with incorrect PIN', () {
      final teacherService = MeshNetworkService(classroomPin: 'secret_classroom_123');
      final attackerService = MeshNetworkService(classroomPin: 'wrong_pin');

      final payloadJson = teacherService.generateDiscoveryPayload();

      final isValid = attackerService.verifyDiscoveryPayload(payloadJson);
      expect(isValid, isFalse);
    });

    test('verifyDiscoveryPayload returns false for malformed payload', () {
      final service = MeshNetworkService(classroomPin: 'test_pin');

      expect(service.verifyDiscoveryPayload('{"msg": "TEACHER_NODE_HERE"}'), isFalse);
      expect(service.verifyDiscoveryPayload('not json'), isFalse);
    });

    test('verifyDiscoveryPayload returns false for expired timestamp', () {
      final service = MeshNetworkService(classroomPin: 'test_pin');

      // Expired timestamp (1 hour ago)
      final expiredTimestamp = DateTime.now().millisecondsSinceEpoch - 3600000;
      final payloadJson = jsonEncode({
        'msg': 'TEACHER_NODE_HERE',
        'timestamp': expiredTimestamp,
        'signature': 'fake_signature', // Doesn't matter because timestamp check fails first, but let's test correctly
      });

      expect(service.verifyDiscoveryPayload(payloadJson), isFalse);
    });
  });
}
