import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/services/mesh_network_service.dart';

class TestMeshNetworkService extends MeshNetworkService {
  TestMeshNetworkService({super.role = MeshRole.studentNode});

  Map<String, dynamic>? lastPayload;

  @override
  void sendOverTcp(Map<String, dynamic> payload) {
    lastPayload = payload;
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
    });
  });
}
