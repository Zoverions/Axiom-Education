import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ontario demonstration defaults remain explicitly non-accredited', () {
    final contract =
        jsonDecode(
              File(
                'contracts/axiom-education-curriculum-assurance.v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final boundaries = contract['claim_boundaries'] as Map<String, dynamic>;
    final ontario =
        contract['ontario_demonstration_default'] as Map<String, dynamic>;
    final claim = (ontario['claim'] as String).toLowerCase();

    expect(ontario['level'], 'source-aligned-demonstration');
    expect(claim, contains('not ministry-approved'));
    expect(claim, contains('ontario credit-bearing course'));
    expect(
      boundaries['source_aligned_demonstration_may_claim_ontario_credit'],
      isFalse,
    );
    expect(
      boundaries['source_aligned_demonstration_implies_human_review'],
      isFalse,
    );
    expect(
      boundaries['lower_assurance_level_may_claim_accreditation'],
      isFalse,
    );
    expect(boundaries['source_evidence_required_for_alignment_claim'], isTrue);
  });
}
