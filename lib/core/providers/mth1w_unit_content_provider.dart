import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/mth1w_unit_content.dart';

const mth1wUnitOneAssetPath =
    'curriculum/content/mth1w/u1-number-systems.v1.json';
const mth1wUnitTwoAssetPath = 'curriculum/content/mth1w/u2-powers.v1.json';
const mth1wUnitThreeAssetPath =
    'curriculum/content/mth1w/u3-rational-applications.v1.json';
const mth1wUnitFourAssetPath =
    'curriculum/content/mth1w/u4-algebraic-thinking.v1.json';
const mth1wUnitFiveAssetPath =
    'curriculum/content/mth1w/u5-coding-relationships.v1.json';
const mth1wUnitSixAssetPath =
    'curriculum/content/mth1w/u6-relations-linear-models.v1.json';
const mth1wUnitSevenAssetPath =
    'curriculum/content/mth1w/u7-data-modelling.v1.json';
const mth1wUnitEightManifestAssetPath =
    'curriculum/content/mth1w/u8/manifest.v1.json';
const mth1wUnitNineManifestAssetPath =
    'curriculum/content/mth1w/u9/manifest.v1.json';

const mth1wUnitAssetPaths = <int, String>{
  1: mth1wUnitOneAssetPath,
  2: mth1wUnitTwoAssetPath,
  3: mth1wUnitThreeAssetPath,
  4: mth1wUnitFourAssetPath,
  5: mth1wUnitFiveAssetPath,
  6: mth1wUnitSixAssetPath,
  7: mth1wUnitSevenAssetPath,
};

const mth1wSplitUnitManifestPaths = <int, String>{
  8: mth1wUnitEightManifestAssetPath,
  9: mth1wUnitNineManifestAssetPath,
};

final mth1wUnitProvider = FutureProvider.family<Mth1wUnitContent, int>((
  ref,
  unitNumber,
) async {
  final expectedUnitId = 'mth1w-u$unitNumber';
  final splitManifest = mth1wSplitUnitManifestPaths[unitNumber];
  if (splitManifest != null) {
    return _loadSplitUnit(splitManifest, expectedUnitId, unitNumber);
  }

  final path = mth1wUnitAssetPaths[unitNumber];
  if (path == null) {
    throw Mth1wUnitContentFormatException(
      'MTH1W draft Unit $unitNumber is not available',
    );
  }
  return _loadUnit(path, expectedUnitId);
});

final mth1wUnitOneProvider = mth1wUnitProvider(1);
final mth1wUnitTwoProvider = mth1wUnitProvider(2);
final mth1wUnitThreeProvider = mth1wUnitProvider(3);
final mth1wUnitFourProvider = mth1wUnitProvider(4);
final mth1wUnitFiveProvider = mth1wUnitProvider(5);
final mth1wUnitSixProvider = mth1wUnitProvider(6);
final mth1wUnitSevenProvider = mth1wUnitProvider(7);
final mth1wUnitEightProvider = mth1wUnitProvider(8);
final mth1wUnitNineProvider = mth1wUnitProvider(9);

Future<Mth1wUnitContent> _loadUnit(String path, String expectedUnitId) async {
  final source = await rootBundle.loadString(path);
  final unit = Mth1wUnitContent.fromJsonString(source);
  return _requireUnitIdentity(unit, path, expectedUnitId);
}

Future<Mth1wUnitContent> _loadSplitUnit(
  String manifestPath,
  String expectedUnitId,
  int unitNumber,
) async {
  final source = await rootBundle.loadString(manifestPath);
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw Mth1wUnitContentFormatException(
      '$manifestPath must contain a JSON object',
    );
  }

  final rawAssets = decoded['lesson_assets'];
  if (rawAssets is! List<dynamic> || rawAssets.isEmpty) {
    throw Mth1wUnitContentFormatException(
      '$manifestPath must declare lesson_assets',
    );
  }
  final prefix = 'curriculum/content/mth1w/u$unitNumber/';
  final assetPaths = <String>[];
  for (final rawPath in rawAssets) {
    if (rawPath is! String ||
        !rawPath.startsWith(prefix) ||
        rawPath.contains('..') ||
        !rawPath.endsWith('.json')) {
      throw Mth1wUnitContentFormatException(
        '$manifestPath contains an invalid lesson asset',
      );
    }
    assetPaths.add(rawPath);
  }
  if (assetPaths.toSet().length != assetPaths.length) {
    throw Mth1wUnitContentFormatException(
      '$manifestPath contains duplicate lesson assets',
    );
  }

  final lessons = <Map<String, dynamic>>[];
  for (final assetPath in assetPaths) {
    final lessonSource = await rootBundle.loadString(assetPath);
    final lesson = jsonDecode(lessonSource);
    if (lesson is! Map<String, dynamic>) {
      throw Mth1wUnitContentFormatException(
        '$assetPath must contain a JSON object',
      );
    }
    lessons.add(lesson);
  }

  final materialized = Map<String, dynamic>.from(decoded)
    ..remove('lesson_assets')
    ..['lessons'] = lessons;
  final unit = Mth1wUnitContent.fromJson(materialized);
  return _requireUnitIdentity(unit, manifestPath, expectedUnitId);
}

Mth1wUnitContent _requireUnitIdentity(
  Mth1wUnitContent unit,
  String path,
  String expectedUnitId,
) {
  if (unit.unitId != expectedUnitId) {
    throw Mth1wUnitContentFormatException(
      '$path contains ${unit.unitId}; expected $expectedUnitId',
    );
  }
  return unit;
}
