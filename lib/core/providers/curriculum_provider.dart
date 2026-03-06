import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatabaseService {
  static Database? _database;

  // Add for testing
  @visibleForTesting
  static void setDatabase(Database db) {
    _database = db;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux) {
      final docDir = await getApplicationSupportDirectory();
      dbPath = docDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }

    final path = join(dbPath, 'ontario_curriculum.sqlite');

    // Always copy the pre-populated sqlite db from assets to the device's db directory
    // If we only wanted to do this once we could check if it exists, but for dev we copy.
    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      try {
        ByteData data = await rootBundle.load("assets/curriculum/ontario_curriculum.sqlite");
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (_) {
        // Fallback or ignore if we cannot write the initial database
        // openDatabase will either create a new blank db or fail gracefully
      }
    }

    return await openDatabase(path, version: 1);
  }
}

// ── Provide db instance ───────────────────────────────────────────────────────
final databaseProvider = FutureProvider<Database>((ref) async {
  return await DatabaseService.database;
});

// ── Course Overview provider ──────────────────────────────────────────────────
class CourseOverview {
  final String id;
  final String name;
  final int expectationCount;

  CourseOverview(this.id, this.name, this.expectationCount);
}

final courseOverviewProvider = FutureProvider<List<CourseOverview>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT c.id, c.name, COUNT(e.id) as count
    FROM Course c
    LEFT JOIN Expectation e ON c.id = e.course_id
    GROUP BY c.id
    ORDER BY c.id ASC
  ''');

  return maps.map((e) => CourseOverview(
    e['id'] as String,
    e['name'] as String,
    e['count'] as int,
  )).toList();
});

// ── Course Details Provider ───────────────────────────────────────────────────
class CourseDetail {
    final String id;
    final String name;
    final List<StrandDetail> strands;

    CourseDetail(this.id, this.name, this.strands);
}

class StrandDetail {
    final String name;
    final List<ExpectationDetail> expectations;

    StrandDetail(this.name, this.expectations);
}

class ExpectationDetail {
    final String text;
    final List<String> tags;

    ExpectationDetail(this.text, this.tags);
}

final courseDetailProvider = FutureProvider.family<CourseDetail, String>((ref, courseId) async {
    final db = await ref.watch(databaseProvider.future);

    // Optimize N+1 query: Fetch course, strands, expectations, and tags with a JOIN
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT
        c.name as course_name,
        s.id as strand_id, s.name as strand_name,
        e.id as exp_id, e.text as exp_text,
        t.tag
      FROM Course c
      LEFT JOIN Strand s ON c.id = s.course_id
      LEFT JOIN Expectation e ON s.id = e.strand_id
      LEFT JOIN Tag t ON e.id = t.expectation_id
      WHERE c.id = ?
    ''', [courseId]);

    if (rows.isEmpty) {
        return CourseDetail(courseId, 'Unknown', []);
    }

    final courseName = rows.first['course_name'] as String;

    // Use linked maps to preserve insertion order (which is typically the DB return order)
    final Map<String, _StrandBuilder> strandBuilders = {};

    for (final row in rows) {
        final strandId = row['strand_id'] as String?;
        if (strandId == null) continue; // No strands for this course

        final strandBuilder = strandBuilders.putIfAbsent(
            strandId, () => _StrandBuilder(row['strand_name'] as String));

        final expId = row['exp_id'] as String?;
        if (expId == null) continue; // No expectations for this strand

        final expBuilder = strandBuilder.expectations.putIfAbsent(
            expId, () => _ExpectationBuilder(row['exp_text'] as String));

        final tag = row['tag'] as String?;
        if (tag != null) {
            expBuilder.tags.add(tag);
        }
    }

    // Build the final detail object
    final List<StrandDetail> strands = strandBuilders.values.map((sBuilder) {
        final expectations = sBuilder.expectations.values.map((eBuilder) {
            return ExpectationDetail(eBuilder.text, eBuilder.tags.toList());
        }).toList();
        return StrandDetail(sBuilder.name, expectations);
    }).toList();

    return CourseDetail(courseId, courseName, strands);
});

class _StrandBuilder {
    final String name;
    final Map<String, _ExpectationBuilder> expectations = {};
    _StrandBuilder(this.name);
}

class _ExpectationBuilder {
    final String text;
    final Set<String> tags = {}; // Use Set to avoid duplicate tags if any
    _ExpectationBuilder(this.text);
}


// ── Flat item bank: every expectation as an IRT-ready map ─────────────────────
// Retaining original backwards compatibility for AdaptiveLessonScreen
final curriculumBankProvider = FutureProvider<List<CurriculumItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);

  // Optimize N+1 query: Fetch all expectations and tags with a JOIN, then group in memory
  final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT e.id, e.course_id, s.name as strand_name, e.text, e.irt_b, e.irt_a, e.irt_c, t.tag
      FROM Expectation e
      JOIN Strand s ON e.strand_id = s.id
      LEFT JOIN Tag t ON e.id = t.expectation_id
  ''');

  final Map<String, CurriculumItem> itemsMap = {};

  for (final row in rows) {
      final expId = row['id'] as String;
      final tag = row['tag'] as String?;

      if (!itemsMap.containsKey(expId)) {
          itemsMap[expId] = CurriculumItem(
              id: expId,
              courseCode: row['course_id'] as String,
              strand: row['strand_name'] as String,
              expectation: row['text'] as String,
              irtB: (row['irt_b'] as num?)?.toDouble() ?? 0.0,
              irtA: (row['irt_a'] as num?)?.toDouble() ?? 1.2,
              irtC: (row['irt_c'] as num?)?.toDouble() ?? 0.2,
              tags: tag != null ? [tag] : [],
          );
      } else if (tag != null) {
          itemsMap[expId]!.tags.add(tag);
      }
  }

  return itemsMap.values.toList();
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
