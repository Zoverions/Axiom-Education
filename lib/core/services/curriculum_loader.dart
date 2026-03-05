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
      SELECT e.id, e.text as expectation, e.irt_b, e.irt_a, e.irt_c, s.name as strand
      FROM Expectation e
      JOIN Strand s ON e.strand_id = s.id
      WHERE e.course_id = ?
    ''', [courseCode]);

    List<Map<String, dynamic>> results = [];
    for (var row in maps) {
        // Must fetch tags separately due to relation
        final tagRows = await db.query('Tag', columns: ['tag'], where: 'expectation_id = ?', whereArgs: [row['id']]);
        final tags = tagRows.map((t) => t['tag'] as String).toList();

        var completeRow = Map<String, dynamic>.from(row);
        completeRow['tags'] = tags;
        results.add(completeRow);
    }
    return results;
  }

  /// Correct Ministry URL mapping.
  static Future<String> officialUrl(String courseCode) async {
    final db = await DatabaseService.database;
    final res = await db.query('Course', columns: ['official_url'], where: 'id = ?', whereArgs: [courseCode]);
    if (res.isNotEmpty && res.first['official_url'] != null) {
      return res.first['official_url'] as String;
    }
    return 'https://www.ontario.ca/page/secondary-school-curriculum';
  }
}
