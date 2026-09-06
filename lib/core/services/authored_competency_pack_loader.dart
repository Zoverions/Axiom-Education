import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/authored_competency_pack.dart';

class AuthoredCompetencyPackLoader {
  const AuthoredCompetencyPackLoader();

  Future<AuthoredCompetencyPack> load(AssetBundle bundle) async {
    final raw = await bundle.loadString(
      AuthoredCompetencyPack.aiNativeAssetPath,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const AuthoredCompetencyPackException(
        'Authored competency pack root must be an object.',
      );
    }
    return AuthoredCompetencyPack.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }
}
