import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

class TestMeshNetworkService extends MeshNetworkService {
  TestMeshNetworkService({super.role = MeshRole.studentNode})
      : super(classroomPin: 'test_pin');

  Map<String, dynamic>? lastPayload;

  @override
  void sendOverTcp(Map<String, dynamic> payload) {
    lastPayload = payload;
  }
}

class FakeSocket extends Fake implements Socket {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  bool destroyed = false;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(Uint8List event) convert) {
    return _controller.stream.asyncMap(convert);
  }

  @override
  void destroy() {
    destroyed = true;
  }

  void simulateError(Object error) {
    _controller.addError(error);
  }

  void simulateDone() {
    _controller.close();
  }

  void simulateData(Uint8List data) {
    _controller.add(data);
  }
}

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
        'signature': 'fake_signature',
      });

      expect(service.verifyDiscoveryPayload(payloadJson), isFalse);
    });
  });

  group('MeshNetworkService', () {
    test('gossipCredential throws exception when not connected', () async {
      final service = MeshNetworkService(classroomPin: 'test_pin');

      await expectLater(
        service.gossipCredential('test_id', {'data': 'test'}),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Not connected to mesh.'))),
      );
    });
  });

  group('MeshNetworkService Tests', () {
    test('startDiscovery falls back to Easy Connection on local mesh failure', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode, classroomPin: 'test_pin');
      final logs = <String>[];

      // Bind to the port beforehand to cause an exception in startDiscovery
      // Teacher node attempts to bind to port 4546.
      final blockingServer = await ServerSocket.bind(InternetAddress.anyIPv4, 4546);

      try {
        await runZoned<Future<void>>(() async {
          await service.startDiscovery();
        }, zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            logs.add(line);
          },
        ));

        // Assert that the fallback was attempted
        expect(
          logs.any((log) => log.contains('Attempting Easy Connection Discovery fallback...')),
          isTrue,
        );
        expect(
          logs.any((log) => log.contains('Connected to Global Educational Network via LEO Satellite.')),
          isTrue,
        );
      } finally {
        await blockingServer.close();
        service.disconnect();
      }
    });
  });

  group('MeshNetworkService gossipCredential', () {
    test('sends correct payload when connected', () async {
      final service = TestMeshNetworkService();
      service.isConnected = true;

      final credentialId = 'test-cred-123';
      final payloadData = {'grade': 'A', 'subject': 'Math'};

      await service.gossipCredential(credentialId, payloadData);

      expect(service.lastPayload, isNotNull);
      expect(service.lastPayload!['type'], equals('CREDENTIAL_GOSSIP'));
      expect(service.lastPayload!['id'], equals(credentialId));
      expect(service.lastPayload!['payload'], equals(payloadData));
    });

    test('throws Exception when not connected', () async {
      final service = TestMeshNetworkService();
      service.isConnected = false;

      final credentialId = 'test-cred-123';
      final payloadData = {'grade': 'A', 'subject': 'Math'};

      expect(
        () => service.gossipCredential(credentialId, payloadData),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Not connected to mesh.'),
          ),
        ),
      );
    });
  });

  group('MeshNetworkService _handleIncomingData Socket Lifecycle Tests', () {
    test('socket.destroy() is called on socket error', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode, classroomPin: 'test_pin');
      final fakeSocket = FakeSocket();

      service.handleIncomingDataForTest(fakeSocket);

      fakeSocket.simulateError(Exception('Simulated Socket Error'));

      // Yield to allow the stream error handler to fire
      await Future.delayed(Duration.zero);

      expect(fakeSocket.destroyed, isTrue);
    });

    test('socket.destroy() is called on socket done', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode, classroomPin: 'test_pin');
      final fakeSocket = FakeSocket();

      service.handleIncomingDataForTest(fakeSocket);

      fakeSocket.simulateDone();

      // Yield to allow the stream done handler to fire
      await Future.delayed(Duration.zero);

      expect(fakeSocket.destroyed, isTrue);
    });

    test('socket receives data correctly and is not destroyed', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode, classroomPin: 'test_pin');
      final fakeSocket = FakeSocket();

      service.handleIncomingDataForTest(fakeSocket);

      // Send some valid JSON to ensure it handles data
      final data = utf8.encode('{"type": "CANVAS_SYNC", "strokes": []}\n');
      fakeSocket.simulateData(Uint8List.fromList(data));

      await Future.delayed(Duration.zero);

      expect(fakeSocket.destroyed, isFalse);
    });
  });
}
