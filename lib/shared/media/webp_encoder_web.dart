import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The browser cannot make WebP. The upload slot asks for WebP, so the photo
/// cannot be sent.
class WebpNotSupportedException implements Exception {
  @override
  String toString() => 'WebpNotSupportedException';
}

const _maxSide = 1600;
const _quality = 0.8;

/// Makes a photo smaller: at most 1600 pixels on the long side, WebP at 80%.
/// The browser draws it (`createImageBitmap` turns it upright using the EXIF
/// data of a phone photo).
Future<Uint8List> encodeWebp(Uint8List bytes) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final bitmap = await web.window.createImageBitmap(blob).toDart;

  final scale =
      _maxSide / (bitmap.width > bitmap.height ? bitmap.width : bitmap.height);
  final ratio = scale < 1 ? scale : 1.0;
  final width = (bitmap.width * ratio).round();
  final height = (bitmap.height * ratio).round();

  final canvas = web.HTMLCanvasElement()
    ..width = width
    ..height = height;
  (canvas.getContext('2d')! as web.CanvasRenderingContext2D).drawImage(
    bitmap,
    0,
    0,
    width.toDouble(),
    height.toDouble(),
  );
  bitmap.close();

  final done = Completer<web.Blob?>();
  canvas.toBlob(
    ((web.Blob? b) => done.complete(b)).toJS,
    'image/webp',
    _quality.toJS,
  );
  final out = await done.future;
  // A browser that cannot make WebP answers with a PNG.
  if (out == null || out.type != 'image/webp') {
    throw WebpNotSupportedException();
  }
  return (await out.arrayBuffer().toDart).toDart.asUint8List();
}
