import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

const testMeshSecret = 'test-only-mesh-secret-with-sufficient-entropy';

class TestMeshNetworkService extends MeshNetworkService {
  TestMeshNetworkService({super.role = MeshRole.studentNode})
      : super(
          classroomPin: 'test_pin',
          meshSecret: testMeshSecret,
          allowLegacyMesh: true,
        );

  Map<String, dynamic>? lastPayload;

  @override
  void sendOverTcp(Map<String, dynamic> payload) {
    lastPayload = payload;
  }
}

class FakeSocket extends Fake implements Socket {
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>();
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
  void destroy() {
    destroyed = true;
  }

  void simulateError(Object error) => _controller.addError(error);

  void simulateDone() => _controller.close();

  void simulateData(List<int> data) {
    _controller.add(Uint8List.fromList(data));
  }
}

void main() {
  group('discovery authentication', () {
    test('generates the expected signed payload shape', () {
      final service = MeshNetworkService(classroomPin: 'test_pin');
      final payload = jsonDecode(service.generateDiscoveryPayload())
          as Map<String, dynamic>;

      expect(payload['msg'], 'TEACHER_NODE_HERE');
      expect(payload['timestamp'], isA<int>());
      expect(payload['nonce'], isA<String>());
      expect(payload['signature'], isA<String>());
      expect((payload['signature'] as String).length, 64);
    });

    test('accepts a valid payload once', () {
      final teacher = MeshNetworkService(classroomPin: 'classroom-secret');
      final student = MeshNetworkService(classroomPin: 'classroom-secret');
      final payload = teacher.generateDiscoveryPayload();

      expect(student.verifyDiscoveryPayload(payload), isTrue);
      expect(student.verifyDiscoveryPayload(payload), isFalse);
    });

    test('rejects wrong PIN, malformed, and expired payloads', () {
      final teacher = MeshNetworkService(classroomPin: 'classroom-secret');
      final attacker = MeshNetworkService(classroomPin: 'wrong-secret');
      expect(
        attacker.verifyDiscoveryPayload(teacher.generateDiscoveryPayload()),
        isFalse,
      );

      expect(attacker.verifyDiscoveryPayload('not-json'), isFalse);
      expect(
        attacker.verifyDiscoveryPayload(
          jsonEncode({
            'msg': 'TEACHER_NODE_HERE',
            'timestamp': DateTime.now().millisecondsSinceEpoch - 3600000,
            'nonce': 'expired',
            'signature': List<String>.filled(64, '0').join(),
          }),
        ),
        isFalse,
      );
    });
  });

  group('fail-closed startup', () {
    test('legacy mesh is disabled by default', () async {
      final service = MeshNetworkService(
        role: MeshRole.teacherNode,
        classroomPin: 'test_pin',
        meshSecret: testMeshSecret,
      );

      await expectLater(
        service.startDiscovery(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('disabled'),
          ),
        ),
      );
      expect(service.isConnected, isFalse);
    });

    test('explicit legacy opt-in still requires a configured key', () async {
      final service = MeshNetworkService(
        role: MeshRole.teacherNode,
        classroomPin: 'test_pin',
        allowLegacyMesh: true,
        meshSecret: '',
      );

      await expectLater(
        service.startDiscovery(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('MESH_SECRET_KEY'),
          ),
        ),
      );
      expect(service.isConnected, isFalse);
    });
  });

  group('authenticated encryption', () {
    test('round-trips a bounded payload with AES-GCM', () {
      final service = MeshNetworkService(
        classroomPin: 'test_pin',
        meshSecret: testMeshSecret,
        allowLegacyMesh: true,
      );
      final payload = {
        'type': 'CANVAS_SYNC',
        'strokes': [
          {'x': 10, 'y': 20, 'pressure': 0.5},
        ],
      };

      final encoded = service.encodePayloadForTest(payload);
      expect(service.decodePayloadForTest(encoded), payload);
    });

    test('rejects tampered ciphertext', () {
      final service = MeshNetworkService(
        classroomPin: 'test_pin',
        meshSecret: testMeshSecret,
        allowLegacyMesh: true,
      );
      final encoded = service.encodePayloadForTest({
        'type': 'CANVAS_SYNC',
        'strokes': <Map<String, dynamic>>[],
      });
      final parts = encoded.trim().split(':');
      final ciphertext = base64.decode(parts[1]);
      ciphertext[0] ^= 0x01;
      final tampered = '${parts[0]}:${base64.encode(ciphertext)}';

      expect(
        () => service.decodePayloadForTest(tampered),
        throwsA(anything),
      );
    });

    test('rejects unsupported message types and excessive strokes', () {
      final service = MeshNetworkService(
        classroomPin: 'test_pin',
        meshSecret: testMeshSecret,
        allowLegacyMesh: true,
      );

      expect(
        () => service.encodePayloadForTest({'type': 'UNKNOWN'}),
        throwsFormatException,
      );
      expect(
        () => service.encodePayloadForTest({
          'type': 'CANVAS_SYNC',
          'strokes': List<Map<String, dynamic>>.generate(
            10001,
            (index) => {'x': index, 'y': index},
          ),
        }),
        throwsFormatException,
      );
    });
  });

  group('bounded domain messages', () {
    test('syncCanvasState sends the expected payload when connected', () async {
      final service = TestMeshNetworkService()..isConnected = true;
      final strokes = [
        {'x': 10, 'y': 20, 'pressure': 0.5},
        {'x': 15, 'y': 25, 'pressure': 0.7},
      ];

      await service.syncCanvasState(strokes);

      expect(service.lastPayload, {
        'type': 'CANVAS_SYNC',
        'strokes': strokes,
      });
    });

    test('syncCanvasState does nothing while disconnected', () async {
      final service = TestMeshNetworkService();
      await service.syncCanvasState([
        {'x': 10, 'y': 20, 'pressure': 0.5},
      ]);
      expect(service.lastPayload, isNull);
    });

    test('gossipCredential requires a connection', () async {
      final service = TestMeshNetworkService();
      await expectLater(
        service.gossipCredential('credential-1', {'grade': 'A'}),
        throwsA(isA<StateError>()),
      );
    });

    test('gossipCredential sends the expected payload when connected', () async {
      final service = TestMeshNetworkService()..isConnected = true;
      await service.gossipCredential('credential-1', {'grade': 'A'});

      expect(service.lastPayload, {
        'type': 'CREDENTIAL_GOSSIP',
        'id': 'credential-1',
        'payload': {'grade': 'A'},
      });
    });
  });

  group('socket lifecycle and framing', () {
    late MeshNetworkService service;
    late FakeSocket socket;

    setUp(() {
      service = MeshNetworkService(
        role: MeshRole.teacherNode,
        classroomPin: 'test_pin',
        meshSecret: testMeshSecret,
        allowLegacyMesh: true,
      );
      socket = FakeSocket();
      service.handleIncomingDataForTest(socket);
    });

    test('destroys a socket on stream error', () async {
      socket.simulateError(Exception('simulated'));
      await Future<void>.delayed(Duration.zero);
      expect(socket.destroyed, isTrue);
    });

    test('destroys a socket when the stream closes', () async {
      socket.simulateDone();
      await Future<void>.delayed(Duration.zero);
      expect(socket.destroyed, isTrue);
    });

    test('accepts a correctly framed encrypted message', () async {
      final message = service.encodePayloadForTest({
        'type': 'CANVAS_SYNC',
        'strokes': <Map<String, dynamic>>[],
      });
      socket.simulateData(utf8.encode(message));
      await Future<void>.delayed(Duration.zero);
      expect(socket.destroyed, isFalse);
    });

    test('closes the socket on malformed UTF-8', () async {
      socket.simulateData([0xC3, 0x28]);
      await Future<void>.delayed(Duration.zero);
      expect(socket.destroyed, isTrue);
    });
  });
}
