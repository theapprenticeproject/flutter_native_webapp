import 'dart:convert';

import 'package:flutter/services.dart';

class AboutTapLoader {
  const AboutTapLoader();

  static const String assetPath = 'assets/profile-screen/about_tap.json';

  Future<Map<String, dynamic>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
