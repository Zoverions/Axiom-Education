import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/mth1w_unit_content.dart';

const mth1wUnitOneAssetPath =
    'curriculum/content/mth1w/u1-number-systems.v1.json';
const mth1wUnitTwoAssetPath = 'curriculum/content/mth1w/u2-powers.v1.json';

final mth1wUnitOneProvider = FutureProvider<Mth1wUnitContent>((ref) async {
  return _loadUnit(mth1wUnitOneAssetPath, 'mth1w-u1');
});

final mth1wUnitTwoProvider = FutureProvider<Mth1wUnitContent>((ref) async {
  return _loadUnit(mth1wUnitTwoAssetPath, 'mth1w-u2');
});

Future<Mth1wUnitContent> _loadUnit(String path, String expectedUnitId) async {
  final source = await rootBundle.loadString(path);
  final unit = Mth1wUnitContent.fromJsonString(source);
  if (unit.unitId != expectedUnitId) {
    throw Mth1wUnitContentFormatException(
      '$path contains ${unit.unitId}; expected $expectedUnitId',
    );
  }
  return unit;
}
