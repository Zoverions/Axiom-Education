import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/governed_memory_runtime.dart';

const expectedProfileSha256 =
    '9289753c2db2eaa4c18653526f248c5b87c83dc2ab1337ef82b46cf8b23af59d';

void main() {
  test('Dart governed memory runtime matches the pinned learner-memory profile', () {
    final bytes = File(
      'contracts/axiom-education-learner-memory.v1.json',
    ).readAsBytesSync();
    expect(bytes, hasLength(971));
    expect(sha256.convert(bytes).toString(), expectedProfileSha256);

    final profile = Map<String, Object?>.from(
      jsonDecode(utf8.decode(bytes)) as Map,
    );
    final eventKinds = Map<String, String>.from(
      profile['event_type_to_memory_kind']! as Map,
    );

    expect(
      eventKinds,
      GovernedEducationMemoryWriter.eventTypeToMemoryKind,
    );
    expect(profile['memory_action'], GovernedEducationMemoryWriter.memoryAction);
    expect(
      profile['metadata_schema'],
      GovernedEducationMemoryWriter.metadataSchema,
    );
    expect(profile['object_id_pattern'], r'^memory_[a-f0-9]{64}$');

    final invariants = Map<String, Object?>.from(
      profile['invariants']! as Map,
    );
    expect(invariants['caller_selects_memory_kind'], isFalse);
    expect(invariants['raw_content_in_learner_event'], isFalse);
    expect(invariants['automatic_tombstone_on_append_failure'], isFalse);
    expect(
      invariants['memory_write_precedes_learner_event_for_new_content'],
      isTrue,
    );
  });
}
