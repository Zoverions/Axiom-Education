import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/models/authored_competency_pack.dart';
import 'package:ontarioedai/core/services/authored_competency_pack_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled AI-native competency pack loads fail-closed identity', () async {
    final pack = await const AuthoredCompetencyPackLoader().load(rootBundle);

    expect(pack.familyId, AuthoredCompetencyPack.aiNativeFamilyId);
    expect(pack.familyVersion, '1.0.0');
    expect(pack.authorship, 'axiom-extension');
    expect(pack.jurisdictionalAuthority, 'none');
    expect(pack.graph.nodes, hasLength(18));
    expect(pack.graph.edges, isEmpty);
  });
}
