import 'dart:async';
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
