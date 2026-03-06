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
    });
  });
}
