import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class CurriculumDatabaseInitializationException implements Exception {
  final String message;
  final Object? cause;

  const CurriculumDatabaseInitializationException(this.message, [this.cause]);

  @override
  String toString() => 'CurriculumDatabaseInitializationException: $message';
}

class DatabaseService {
  static const String assetPath =
      'assets/curriculum/ontario_curriculum.sqlite';
  static const int databaseAssetVersion = 1;
  static const String databaseFileName =
      'ontario_curriculum_v$databaseAssetVersion.sqlite';
  static const Set<String> requiredTables = {
    'Course',
    'Strand',
    'Expectation',
    'Tag',
  };

  static Database? _database;

  @visibleForTesting
  static void setDatabase(Database db) {
    _database = db;
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  static Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final initialized = await _initDB();
    _database = initialized;
    return initialized;
  }

  static Future<Database> _initDB() async {
    final storagePath = await _resolveStoragePath();
    final databasePath = join(storagePath, databaseFileName);

    if (!await databaseExists(databasePath)) {
      await _materializeBundledDatabase(databasePath);
    }

    try {
      return await _openVerifiedDatabase(databasePath);
    } catch (_) {
      try {
        await _replaceBundledDatabase(databasePath);
        return await _openVerifiedDatabase(databasePath);
      } catch (error) {
        throw CurriculumDatabaseInitializationException(
          'The bundled curriculum database failed validation after a clean '
          'restore.',
          error,
        );
      }
    }
  }

  static Future<Database> _openVerifiedDatabase(String databasePath) async {
    final database = await openDatabase(databasePath, readOnly: true);
    try {
      await _verifySchema(database);
      return database;
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  static Future<String> _resolveStoragePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getApplicationSupportDirectory();
      return directory.path;
    }
    return getDatabasesPath();
  }

  static Future<void> _replaceBundledDatabase(String databasePath) async {
    try {
      final databaseFile = File(databasePath);
      if (await databaseFile.exists()) {
        await databaseFile.delete();
      }
      await _materializeBundledDatabase(databasePath);
    } catch (error) {
      throw CurriculumDatabaseInitializationException(
        'Unable to restore the bundled curriculum database.',
        error,
      );
    }
  }

  static Future<void> _materializeBundledDatabase(
    String databasePath,
  ) async {
    try {
      await Directory(dirname(databasePath)).create(recursive: true);
    } catch (error) {
      throw CurriculumDatabaseInitializationException(
        'Unable to create the curriculum database directory.',
        error,
      );
    }

    final temporaryPath = '$databasePath.tmp';
    final temporaryFile = File(temporaryPath);

    try {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      final data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) {
        throw const FormatException('Bundled curriculum database is empty.');
      }
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await temporaryFile.writeAsBytes(bytes, flush: true);
      if (!await temporaryFile.exists() ||
          await temporaryFile.length() != bytes.length) {
        throw const FileSystemException(
          'Curriculum database copy verification failed.',
        );
      }

      final databaseFile = File(databasePath);
      if (await databaseFile.exists()) {
        await databaseFile.delete();
      }
      await temporaryFile.rename(databasePath);
    } catch (error) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      throw CurriculumDatabaseInitializationException(
        'Unable to materialize the bundled curriculum database.',
        error,
      );
    }
  }

  static Future<void> _verifySchema(Database database) async {
    final placeholders = List.filled(requiredTables.length, '?').join(',');
    final rows = await database.rawQuery(
      'SELECT name FROM sqlite_master '
      'WHERE type = ? AND name IN ($placeholders)',
      ['table', ...requiredTables],
    );
    final discovered = rows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    final missing = requiredTables.difference(discovered);
    if (missing.isNotEmpty) {
      throw CurriculumDatabaseInitializationException(
        'Curriculum database is missing required tables: '
        '${missing.toList()..sort()}.',
      );
    }

    final courseCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM Course'),
        ) ??
        0;
    final expectationCount = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM Expectation'),
        ) ??
        0;
    if (courseCount == 0 || expectationCount == 0) {
      throw const CurriculumDatabaseInitializationException(
        'Curriculum database contains no usable course expectations.',
      );
    }
  }
}

final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseService.database;
});

class CourseOverview {
  final String id;
  final String name;
  final int expectationCount;

  const CourseOverview(this.id, this.name, this.expectationCount);
}

final courseOverviewProvider = FutureProvider<List<CourseOverview>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final maps = await db.rawQuery('''
    SELECT c.id, c.name, COUNT(e.id) as count
    FROM Course c
    LEFT JOIN Expectation e ON c.id = e.course_id
    GROUP BY c.id, c.name
    ORDER BY c.id ASC
  ''');

  return maps
      .map(
        (record) => CourseOverview(
          record['id'] as String,
          record['name'] as String,
          record['count'] as int,
        ),
      )
      .toList(growable: false);
});

class CourseDetail {
  final String id;
  final String name;
  final List<StrandDetail> strands;

  const CourseDetail(this.id, this.name, this.strands);
}

class StrandDetail {
  final String name;
  final List<ExpectationDetail> expectations;

  const StrandDetail(this.name, this.expectations);
}

class ExpectationDetail {
  final String text;
  final List<String> tags;

  const ExpectationDetail(this.text, this.tags);
}

final courseDetailProvider = FutureProvider.family<CourseDetail, String>(
  (ref, courseId) async {
    final db = await ref.watch(databaseProvider.future);
    final rows = await db.rawQuery(
      '''
      SELECT
        c.name as course_name,
        s.id as strand_id,
        s.name as strand_name,
        e.id as exp_id,
        e.text as exp_text,
        t.tag
      FROM Course c
      LEFT JOIN Strand s ON c.id = s.course_id
      LEFT JOIN Expectation e ON s.id = e.strand_id
      LEFT JOIN Tag t ON e.id = t.expectation_id
      WHERE c.id = ?
      ORDER BY s.id ASC, e.id ASC, t.tag ASC
      ''',
      [courseId],
    );

    if (rows.isEmpty) {
      return CourseDetail(courseId, 'Unknown', const []);
    }

    final courseName = rows.first['course_name'] as String;
    final strandBuilders = <String, _StrandBuilder>{};

    for (final row in rows) {
      final strandId = row['strand_id'] as String?;
      if (strandId == null) continue;

      final strandBuilder = strandBuilders.putIfAbsent(
        strandId,
        () => _StrandBuilder(row['strand_name'] as String),
      );

      final expectationId = row['exp_id'] as String?;
      if (expectationId == null) continue;

      final expectationBuilder = strandBuilder.expectations.putIfAbsent(
        expectationId,
        () => _ExpectationBuilder(row['exp_text'] as String),
      );
      final tag = row['tag'] as String?;
      if (tag != null) expectationBuilder.tags.add(tag);
    }

    final strands = strandBuilders.values.map((strandBuilder) {
      final expectations = strandBuilder.expectations.values
          .map(
            (expectationBuilder) => ExpectationDetail(
              expectationBuilder.text,
              expectationBuilder.tags.toList()..sort(),
            ),
          )
          .toList(growable: false);
      return StrandDetail(strandBuilder.name, expectations);
    }).toList(growable: false);

    return CourseDetail(courseId, courseName, strands);
  },
);

class _StrandBuilder {
  final String name;
  final Map<String, _ExpectationBuilder> expectations = {};

  _StrandBuilder(this.name);
}

class _ExpectationBuilder {
  final String text;
  final Set<String> tags = {};

  _ExpectationBuilder(this.text);
}

final curriculumBankProvider = FutureProvider<List<CurriculumItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final rows = await db.rawQuery('''
    SELECT
      e.id,
      e.course_id,
      s.name as strand_name,
      e.text,
      e.irt_b,
      e.irt_a,
      e.irt_c,
      t.tag
    FROM Expectation e
    JOIN Strand s ON e.strand_id = s.id
    LEFT JOIN Tag t ON e.id = t.expectation_id
    ORDER BY e.course_id ASC, e.id ASC, t.tag ASC
  ''');

  final items = <String, CurriculumItem>{};
  for (final row in rows) {
    final expectationId = row['id'] as String;
    final tag = row['tag'] as String?;
    final existing = items[expectationId];

    if (existing == null) {
      items[expectationId] = CurriculumItem(
        id: expectationId,
        courseCode: row['course_id'] as String,
        strand: row['strand_name'] as String,
        expectation: row['text'] as String,
        irtB: (row['irt_b'] as num?)?.toDouble() ?? 0.0,
        irtA: (row['irt_a'] as num?)?.toDouble() ?? 1.2,
        irtC: (row['irt_c'] as num?)?.toDouble() ?? 0.2,
        tags: tag == null ? [] : [tag],
      );
    } else if (tag != null) {
      existing.tags.add(tag);
    }
  }

  return items.values.toList(growable: false);
});

final filteredItemsProvider =
    Provider.family<AsyncValue<List<CurriculumItem>>, CurriculumFilter>(
  (ref, filter) {
    return ref.watch(curriculumBankProvider).whenData(
          (items) => items
              .where(
                (item) =>
                    (filter.courseCode == null ||
                        item.courseCode == filter.courseCode) &&
                    (filter.tag == null || item.tags.contains(filter.tag)) &&
                    item.irtB >= filter.minDifficulty &&
                    item.irtB <= filter.maxDifficulty,
              )
              .toList()
            ..sort((left, right) => left.irtB.compareTo(right.irtB)),
        );
  },
);

class CurriculumItem {
  final String id;
  final String courseCode;
  final String strand;
  final String expectation;
  final double irtB;
  final double irtA;
  final double irtC;
  final List<String> tags;

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

  Map<String, dynamic> toIrtItem() => {
        'id': id,
        'b': irtB,
        'a': irtA,
        'c': irtC,
        'text': expectation,
      };
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

  factory CurriculumFilter.aroundTheta(
    double theta, {
    String? courseCode,
  }) {
    return CurriculumFilter(
      courseCode: courseCode,
      minDifficulty: theta - 1.5,
      maxDifficulty: theta + 1.5,
    );
  }
}
