import 'package:sqflite/sqflite.dart';
import '../providers/curriculum_provider.dart';

class CurriculumLoader {
  static const String verificationNote =
      '© King\'s Printer for Ontario – Supplementary use only. '
      'Official source: dcp.edu.gov.on.ca';

  /// Returns all expectations for a course as typed, safe list.
  static Future<List<Map<String, dynamic>>> getExpectationsForCourse(
      String courseCode) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.id, e.text as expectation, e.irt_b, e.irt_a, e.irt_c, s.name as strand, t.tag
      FROM Expectation e
      JOIN Strand s ON e.strand_id = s.id
      LEFT JOIN Tag t ON e.id = t.expectation_id
      WHERE e.course_id = ?
    ''', [courseCode]);

    final Map<String, Map<String, dynamic>> resultsMap = {};
    for (var row in maps) {
      final id = row['id'] as String;
      if (!resultsMap.containsKey(id)) {
        var newRow = Map<String, dynamic>.from(row);
        newRow.remove('tag');
        newRow['tags'] = <String>[];
        resultsMap[id] = newRow;
      }

      if (row['tag'] != null) {
        (resultsMap[id]!['tags'] as List<String>).add(row['tag'] as String);
      }
    }
    return resultsMap.values.toList();
  }

  /// Correct Ministry URL mapping.
  static Future<String> officialUrl(String courseCode) async {
    final db = await DatabaseService.database;
    final res = await db.query('Course',
        columns: ['official_url'], where: 'id = ?', whereArgs: [courseCode]);
    if (res.isNotEmpty && res.first['official_url'] != null) {
      return res.first['official_url'] as String;
    }
    return 'https://www.ontario.ca/page/secondary-school-curriculum';
  }
}
