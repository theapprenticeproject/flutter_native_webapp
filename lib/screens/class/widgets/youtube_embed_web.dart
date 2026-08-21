import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildYoutubeEmbed(String youtubeId) {
  final viewType = 'youtube-iframe-$youtubeId';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = web.HTMLIFrameElement()
      ..src = 'https://www.youtube.com/embed/$youtubeId'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..allowFullscreen = true;
    return iframe;
  });

  return HtmlElementView(viewType: viewType);
}

