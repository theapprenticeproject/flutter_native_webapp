import 'dart:typed_data';

/// shortcut: v1 runs on the web only (R-3x, the WhatsApp browser). Other
/// platforms send the photo as it is. Add a native encoder with the app.
Future<Uint8List> encodeWebp(Uint8List bytes) async => bytes;
