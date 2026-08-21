import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/class_chat_message_model.dart';
import '../../../providers/class_chat_controller.dart';
import 'youtube_embed_stub.dart'
    if (dart.library.html) 'youtube_embed_web.dart';

class ClassVideoCard extends StatefulWidget {
  const ClassVideoCard({
    required this.message,
    required this.controller,
    super.key,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  State<ClassVideoCard> createState() => _ClassVideoCardState();
}

class _ClassVideoCardState extends State<ClassVideoCard> {
  YoutubePlayerController? _ytController;
  String? _initializedForYoutubeId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    final youtubeId = widget.message.data['youtubeId'] as String? ?? '';
    if (youtubeId.isNotEmpty) {
      _ensureController(youtubeId);
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  void _ensureController(String youtubeId) {
    if (_initializedForYoutubeId == youtubeId && _ytController != null) return;
    _ytController?.dispose();
    _ytController = YoutubePlayerController(
      initialVideoId: youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: false,
        forceHD: false,
      ),
    )..cue(youtubeId);
    _initializedForYoutubeId = youtubeId;
  }

  @override
  Widget build(BuildContext context) {
    final watched = widget.message.data['watched'] == true;
    final title = widget.message.data['title'] as String? ?? '';
    final points = widget.message.data['points'] as int? ?? 0;
    final youtubeId = widget.message.data['youtubeId'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.classroomMessageSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Watch the video 👇',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.volume_up_rounded,
                size: 16,
                color: AppTheme.buttonColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.classroomMessageSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.classroomMessageSurface),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: youtubeId.isEmpty
                    ? const _EmptyVideoPlaceholder()
                    : kIsWeb
                    ? _WebYoutubePlayer(youtubeId: youtubeId)
                    : AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _ytController == null
                            ? Container(color: AppTheme.classroomMessageSurface)
                            : YoutubePlayer(
                                key: ValueKey('yt_$youtubeId'),
                                controller: _ytController!,
                                showVideoProgressIndicator: true,
                                progressIndicatorColor: AppTheme.buttonColor,
                              ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                'Watch: $title',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: watched ? null : widget.controller.markVideoWatched,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonColor,
              foregroundColor: AppTheme.cardBackground,
              disabledBackgroundColor: AppTheme.dividerColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              watched ? 'Watched' : 'I watched it • +$points points',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyVideoPlaceholder extends StatelessWidget {
  const _EmptyVideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: AppTheme.classroomMessageSurface,
        child: const Center(
          child: Icon(
            Icons.play_arrow_rounded,
            size: 72,
            color: AppTheme.buttonColor,
          ),
        ),
      ),
    );
  }
}

class _WebYoutubePlayer extends StatelessWidget {
  const _WebYoutubePlayer({required this.youtubeId});

  final String youtubeId;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: AppTheme.classroomMessageSurface,
        child: buildYoutubeEmbed(youtubeId),
      ),
    );
  }
}
