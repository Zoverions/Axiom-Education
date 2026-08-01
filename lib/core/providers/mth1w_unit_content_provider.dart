import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../learning/mth1w_unit_content.dart';

const mth1wUnitOneAssetPath =
    'curriculum/content/mth1w/u1-number-systems.v1.json';

final mth1wUnitOneProvider = FutureProvider<Mth1wUnitContent>((ref) async {
  final source = await rootBundle.loadString(mth1wUnitOneAssetPath);
  return Mth1wUnitContent.fromJsonString(source);
});
