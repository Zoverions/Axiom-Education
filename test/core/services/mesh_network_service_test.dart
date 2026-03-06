import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

class TestMeshNetworkService extends MeshNetworkService {
  TestMeshNetworkService({super.role = MeshRole.studentNode});

  Map<String, dynamic>? lastPayload;

  @override
  void sendOverTcp(Map<String, dynamic> payload) {
    lastPayload = payload;
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

void main() {
  group('MeshNetworkService Tests', () {
    test('startDiscovery falls back to Easy Connection on local mesh failure', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode);
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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

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
  group('MeshNetworkService _handleIncomingData Socket Lifecycle Tests', () {
    test('socket.destroy() is called on socket error', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode);
      final fakeSocket = FakeSocket();

      service.handleIncomingDataForTest(fakeSocket);

      fakeSocket.simulateError(Exception('Simulated Socket Error'));

      // Yield to allow the stream error handler to fire
      await Future.delayed(Duration.zero);

      expect(fakeSocket.destroyed, isTrue);
    });

    test('socket.destroy() is called on socket done', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode);
      final fakeSocket = FakeSocket();

      service.handleIncomingDataForTest(fakeSocket);

      fakeSocket.simulateDone();

      // Yield to allow the stream done handler to fire
      await Future.delayed(Duration.zero);

      expect(fakeSocket.destroyed, isTrue);
    });

    test('socket receives data correctly and is not destroyed', () async {
      final service = MeshNetworkService(role: MeshRole.teacherNode);
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
