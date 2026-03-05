import 'dart:convert';
import 'package:flutter/services.dart';

class CurriculumLoader {
  static const String verificationNote =
      '© King\'s Printer for Ontario – Supplementary use only. '
      'Official source: dcp.edu.gov.on.ca';

  static Future<Map<String, dynamic>> loadFullCurriculum() async {
    final s = await rootBundle
        .loadString('assets/curriculum/ontario_curriculum_full.json');
    return jsonDecode(s) as Map<String, dynamic>;
  }

  /// Returns all expectations for a course as typed, safe list.
  /// FIXED: v4.2's expand() cast threw TypeError — now fully typed.
  static Future<List<Map<String, dynamic>>> getExpectationsForCourse(
      String courseCode) async {
    final data = await loadFullCurriculum();
    final courses = data['courses'] as Map<String, dynamic>;
    final course = courses[courseCode] as Map<String, dynamic>?;
    if (course == null) return [];
    final strands = course['strands'] as Map<String, dynamic>;
    return strands.values
        .expand((strand) => (strand as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Correct Ministry URL mapping.
  /// FIXED: v4.2 used courseCode.toLowerCase() which produces invalid paths.
  static String officialUrl(String courseCode) {
    const urlMap = {
      'MTH1W': 'https://www.dcp.edu.gov.on.ca/en/curriculum/mathematics/grade9',
      'MFM2P': 'https://www.dcp.edu.gov.on.ca/en/curriculum/mathematics/grade10',
      'MCR3U': 'https://www.dcp.edu.gov.on.ca/en/curriculum/mathematics/grade11',
      'MHF4U': 'https://www.dcp.edu.gov.on.ca/en/curriculum/mathematics/grade12',
      'ENL1W': 'https://www.dcp.edu.gov.on.ca/en/curriculum/english/grade9',
      'ENG2D': 'https://www.dcp.edu.gov.on.ca/en/curriculum/english/grade10',
      'ENG3U': 'https://www.dcp.edu.gov.on.ca/en/curriculum/english/grade11',
      'ENG4U': 'https://www.dcp.edu.gov.on.ca/en/curriculum/english/grade12',
      'SNC1W': 'https://www.dcp.edu.gov.on.ca/en/curriculum/science/grade9',
      'SNC2D': 'https://www.dcp.edu.gov.on.ca/en/curriculum/science/grade10',
      'CGC1W': 'https://www.dcp.edu.gov.on.ca/en/curriculum/canadian-world-studies/grade9',
      'CHC2D': 'https://www.dcp.edu.gov.on.ca/en/curriculum/canadian-world-studies/grade10',
      'CHV2O': 'https://www.dcp.edu.gov.on.ca/en/curriculum/canadian-world-studies/grade10',
      'BEM1O': 'https://www.dcp.edu.gov.on.ca/en/curriculum/business-studies/grade9',
      'GLC2O': 'https://www.dcp.edu.gov.on.ca/en/curriculum/guidance-and-career-education',
      'ICS3U': 'https://www.dcp.edu.gov.on.ca/en/curriculum/computer-studies/grade11',
    };
    return urlMap[courseCode] ??
        'https://www.ontario.ca/page/secondary-school-curriculum';
  }
}
