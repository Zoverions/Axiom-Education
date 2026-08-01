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

const mth1wUnitAssetPaths = <int, String>{
  1: mth1wUnitOneAssetPath,
  2: mth1wUnitTwoAssetPath,
  3: mth1wUnitThreeAssetPath,
  4: mth1wUnitFourAssetPath,
  5: mth1wUnitFiveAssetPath,
  6: mth1wUnitSixAssetPath,
};

final mth1wUnitProvider = FutureProvider.family<Mth1wUnitContent, int>((
  ref,
  unitNumber,
) async {
  final path = mth1wUnitAssetPaths[unitNumber];
  if (path == null) {
    throw Mth1wUnitContentFormatException(
      'MTH1W draft Unit $unitNumber is not available',
    );
  }
  return _loadUnit(path, 'mth1w-u$unitNumber');
});

final mth1wUnitOneProvider = mth1wUnitProvider(1);
final mth1wUnitTwoProvider = mth1wUnitProvider(2);
final mth1wUnitThreeProvider = mth1wUnitProvider(3);
final mth1wUnitFourProvider = mth1wUnitProvider(4);
final mth1wUnitFiveProvider = mth1wUnitProvider(5);
final mth1wUnitSixProvider = mth1wUnitProvider(6);

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
