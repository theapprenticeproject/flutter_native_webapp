import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  // Inter is bundled in assets/google_fonts/. Never download fonts at runtime:
  // on a slow network inside WhatsApp the text would be late or in another font.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const ProviderScope(child: App()));
}
