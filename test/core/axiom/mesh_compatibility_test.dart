import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/mesh_compatibility.dart';

void main() {
  test('Dart compatibility constants match the canonical JSON profile', () {
    final payload =
        jsonDecode(
              File(
                'config/axiom-mesh-compatibility.v1.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final baseline = payload['mesh_baseline']! as Map<String, Object?>;
    final seam =
        payload['gateway_intents_submit_seam']! as Map<String, Object?>;
    final required = payload['required_runtime_contracts']! as List<Object?>;
    final digests = <String, String>{
      for (final item in required.cast<Map<String, Object?>>())
        item['id']! as String: item['sha256']! as String,
    };
    final learnerMemory = required.cast<Map<String, Object?>>().singleWhere(
      (item) => item['id'] == 'axiom.education.learner-memory.v1',
    );

    expect(
      payload['profile_id'],
      AxiomMeshCompatibilityProfile.currentProfileId,
    );
    expect(
      baseline['kernel_version'],
      AxiomMeshCompatibilityProfile.currentKernelVersion,
    );
    expect(
      baseline['head_sha'],
      AxiomMeshCompatibilityProfile.currentBaselineHead,
    );
    expect(baseline['head_role'], 'observed-provenance-not-runtime-binding');
    expect(
      learnerMemory['source_sha'],
      AxiomMeshCompatibilityProfile.currentProviderHead,
    );
    expect(
      baseline['gateway_contract_source_sha'],
      AxiomMeshCompatibilityProfile.currentGatewayContractSourceHead,
    );
    expect(
      baseline['gateway_contract_canonical_sha256'],
      AxiomMeshCompatibilityProfile.currentGatewayContractCanonicalSha256,
    );
    expect(
      baseline['gateway_compatibility_mode'],
      AxiomMeshCompatibilityProfile.currentGatewayCompatibilityMode,
    );
    expect(
      seam['sha256'],
      AxiomMeshCompatibilityProfile.currentGatewayIntentsSubmitSeamSha256,
    );
    expect(
      (baseline['authority_path']! as List<Object?>).cast<String>(),
      AxiomMeshCompatibilityProfile.currentAuthorityPath,
    );
    expect(
      digests,
      AxiomMeshCompatibilityProfile.currentRequiredContractSha256,
    );
    expect(
      const AxiomMeshCompatibilityProfile.current().bindingRejectionReason(),
      isNull,
    );
  });
}
