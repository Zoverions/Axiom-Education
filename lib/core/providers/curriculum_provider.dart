import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Raw JSON load (cached: loads once, never re-reads asset) ──────────────────
final _rawCurriculumProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final json = await rootBundle.loadString(
      'assets/curriculum/ontario_curriculum_full.json');
  return jsonDecode(json) as Map<String, dynamic>;
});

// ── Flat item bank: every expectation as an IRT-ready map ─────────────────────
final curriculumBankProvider =
    FutureProvider<List<CurriculumItem>>((ref) async {
  final raw = await ref.watch(_rawCurriculumProvider.future);
  final courses = raw['courses'] as Map<String, dynamic>;
  final items = <CurriculumItem>[];
  for (final entry in courses.entries) {
    final code = entry.key;
    final course = entry.value as Map<String, dynamic>;
    final strands = course['strands'] as Map<String, dynamic>;
    for (final strandEntry in strands.entries) {
      final expectations = strandEntry.value as List<dynamic>;
      for (final e in expectations) {
        final map = e as Map<String, dynamic>;
        items.add(CurriculumItem(
          id: map['id'] as String,
          courseCode: code,
          strand: strandEntry.key,
          expectation: map['expectation'] as String,
          irtB: (map['irt_b'] as num).toDouble(),
          irtA: (map['irt_a'] as num? ?? 1.2).toDouble(),
          irtC: (map['irt_c'] as num? ?? 0.2).toDouble(),
          tags: List<String>.from(map['tags'] as List? ?? []),
        ));
      }
    }
  }
  return items;
});

// ── Search index: filter by grade, subject, band ──────────────────────────────
final filteredItemsProvider =
    Provider.family<AsyncValue<List<CurriculumItem>>, CurriculumFilter>(
  (ref, filter) {
    return ref.watch(curriculumBankProvider).whenData((items) => items
        .where((item) =>
            (filter.courseCode == null ||
                item.courseCode == filter.courseCode) &&
            (filter.tag == null || item.tags.contains(filter.tag)) &&
            item.irtB >= filter.minDifficulty &&
            item.irtB <= filter.maxDifficulty)
        .toList()
      ..sort((a, b) => a.irtB.compareTo(b.irtB)));
  },
);

// ── Data classes ──────────────────────────────────────────────────────────────
class CurriculumItem {
  final String id;
  final String courseCode;
  final String strand;
  final String expectation;
  final double irtB; // difficulty
  final double irtA; // discrimination
  final double irtC; // guessing
  final List<String> tags; // 'stylus','reading','math','writing','eqao'

  const CurriculumItem({
    required this.id,
    required this.courseCode,
    required this.strand,
    required this.expectation,
    required this.irtB,
    required this.irtA,
    required this.irtC,
    required this.tags,
  });

  Map<String, dynamic> toIrtItem() =>
      {'id': id, 'b': irtB, 'a': irtA, 'c': irtC, 'text': expectation};
}

class CurriculumFilter {
  final String? courseCode;
  final String? tag;
  final double minDifficulty;
  final double maxDifficulty;

  const CurriculumFilter({
    this.courseCode,
    this.tag,
    this.minDifficulty = -4.0,
    this.maxDifficulty = 4.0,
  });

  // Convenience: filter to theta ± 1.5 (maximum Fisher information zone)
  factory CurriculumFilter.aroundTheta(double theta, {String? courseCode}) =>
      CurriculumFilter(
        courseCode: courseCode,
        minDifficulty: theta - 1.5,
        maxDifficulty: theta + 1.5,
      );
}
