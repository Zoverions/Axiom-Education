import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontarioedai/core/axiom/governed_memory_runtime.dart';

const expectedProfileSha256 =
    '3763a28919d36721467160ef772e30da1d5a536a8733fd88b65f2c60c9107d78';

void main() {
  test(
    'Dart governed memory runtime matches the pinned learner-memory profile',
    () {
      final bytes = File(
        'contracts/axiom-education-learner-memory.v1.json',
      ).readAsBytesSync();
      expect(bytes, hasLength(1246));
      expect(sha256.convert(bytes).toString(), expectedProfileSha256);

      final profile = Map<String, Object?>.from(
        jsonDecode(utf8.decode(bytes)) as Map,
      );
      final eventKinds = Map<String, String>.from(
        profile['event_type_to_memory_kind']! as Map,
      );
      final eventOwners = Map<String, String>.from(
        profile['event_type_to_memory_owner']! as Map,
      );

      expect(profile['profile_version'], '1.1.0');
      expect(eventKinds, GovernedEducationMemoryWriter.eventTypeToMemoryKind);
      expect(eventOwners, GovernedEducationMemoryWriter.eventTypeToMemoryOwner);
      expect(
        profile['memory_action'],
        GovernedEducationMemoryWriter.memoryAction,
      );
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
      expect(invariants['memory_owner_binding_required'], isTrue);
      expect(
        invariants['memory_write_precedes_learner_event_for_new_content'],
        isTrue,
      );
    },
  );
}
