import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

void main() {
  group('MeshNetworkService', () {
    test('gossipCredential throws exception when not connected', () async {
      final service = MeshNetworkService();

      await expectLater(
        service.gossipCredential('test_id', {'data': 'test'}),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Not connected to mesh.'))),
      );
    });
  });
}
