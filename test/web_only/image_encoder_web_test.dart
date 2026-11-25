@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/media/image_encoder.dart';
import 'package:web/web.dart' as web;

/// Runs in a real browser: `flutter test --platform chrome test/web_only`.
Future<Uint8List> _png(int w, int h) async {
  final canvas = web.HTMLCanvasElement()
    ..width = w
    ..height = h;
  final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
  ctx.fillStyle = '#3366cc'.toJS;
  ctx.fillRect(0, 0, w.toDouble(), h.toDouble());
  final done = Completer<web.Blob?>();
  canvas.toBlob(((web.Blob? b) => done.complete(b)).toJS, 'image/png');
  final blob = (await done.future)!;
  return (await blob.arrayBuffer().toDart).toDart.asUint8List();
}

bool _isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

Future<({int w, int h})> _size(Uint8List webp) async {
  final bitmap = await web.window
      .createImageBitmap(web.Blob([webp.toJS].toJS))
      .toDart;
  return (w: bitmap.width, h: bitmap.height);
}

void main() {
  test('makes a real JPEG that is smaller than the PNG', () async {
    final png = await _png(800, 600);
    final webp = await encodeImage(png, 'image/jpeg');
    expect(_isJpeg(webp), isTrue);
    expect(webp.length, lessThan(png.length));
  });

  test(
    'a big photo is scaled to 1600 on the long side, keeping the shape',
    () async {
      final webp = await encodeImage(await _png(3200, 2400), 'image/jpeg');
      final size = await _size(webp);
      expect(size.w, 1600);
      expect(size.h, 1200);
    },
  );

  test('a small photo is not made bigger', () async {
    final size = await _size(
      await encodeImage(await _png(400, 300), 'image/jpeg'),
    );
    expect(size.w, 400);
    expect(size.h, 300);
  });
}
