import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/media/file_kind.dart';
import '../ask_tap_launcher.dart';
import '../../../../shared/widgets/dashed_upload_box.dart';
import 'friends_made_row.dart';
import 'media_source_sheet.dart';
import 'submission_confirm_dialog.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/class_chat_message_model.dart';
import '../../../../shared/text/first_name.dart';
import '../../models/submission_answer_model.dart';
import '../../providers/class_chat_controller.dart';
import 'class_card_shell.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_tonal_button.dart';

class ClassSubmissionCard extends StatefulWidget {
  const ClassSubmissionCard({
    super.key,
    required this.message,
    required this.controller,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  State<ClassSubmissionCard> createState() => _ClassSubmissionCardState();
}

class _ClassSubmissionCardState extends State<ClassSubmissionCard> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedEmoji;
  XFile? _pickedMedia;
  Uint8List? _pickedMediaBytes;
  bool _isVideoPick = false;
  bool _isPicking = false;
  bool _submitted = false;
  bool _pickError = false;

  /// The file is not a photo (or video): the red box of design M-S-05.
  bool _wrongFile = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.data['autoPick'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final kind = SubmissionKindResolver.fromSubTypes(
          widget.message.data['subTypes'] as String? ?? '',
        );
        if (mounted &&
            _isMediaKind(kind) &&
            widget.controller.isAwaitingInput) {
          _chooseFile(
            allowVideo: kind != SubmissionKind.image,
            forceVideo: kind == SubmissionKind.video,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _markSubmitted() {
    setState(() => _submitted = true);
  }

  /// Sends the picked photo or video. The controller uploads it to the Worker.
  Future<void> _submitMedia({required bool isVideo}) async {
    final file = _pickedMedia;
    if (file == null) return;
    _markSubmitted();
    try {
      final bytes = _pickedMediaBytes ?? await file.readAsBytes();
      await widget.controller.submitAssignmentAnswer(
        isVideo
            ? SubmissionAnswer.video(file.path, bytes: bytes)
            : SubmissionAnswer.image(file.path, bytes: bytes),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitted = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.classFileReadFailed)));
    }
  }

  bool _isRight(XFile file, {required bool video}) {
    final ok = isRightFile(
      mimeType: file.mimeType,
      name: file.name,
      video: video,
    );
    if (!ok && mounted) setState(() => _wrongFile = true);
    return ok;
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPicking = true;
      _pickError = false;
      _wrongFile = false;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        if (!_isRight(file, video: false)) return;
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedMedia = file;
          _pickedMediaBytes = bytes;
          _isVideoPick = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pickError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.classFileAccessFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    setState(() {
      _isPicking = true;
      _pickError = false;
      _wrongFile = false;
    });
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (file != null) {
        if (!_isRight(file, video: true)) return;
        if (!mounted) return;
        setState(() {
          _pickedMedia = file;
          _pickedMediaBytes = null;
          _isVideoPick = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pickError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.classFileAccessFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// A photo or a video (the activity accepts both): one chooser for both.
  Future<void> _pickPhotoOrVideo() async {
    setState(() {
      _isPicking = true;
      _pickError = false;
      _wrongFile = false;
    });
    try {
      final file = await _picker.pickMedia(imageQuality: 85);
      if (file != null) {
        final video = isRightFile(
          mimeType: file.mimeType,
          name: file.name,
          video: true,
        );
        if (!video && !_isRight(file, video: false)) return;
        final bytes = video ? null : await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedMedia = file;
          _pickedMediaBytes = bytes;
          _isVideoPick = video;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pickError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.classFileAccessFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// Opens the phone's own chooser (design M-S-02: "Choose an action" with
  /// Camera, Photos and Files). On the web a file input makes the phone draw it,
  /// so the app has no source sheet of its own.
  Future<void> _chooseFile({
    required bool allowVideo,
    bool forceVideo = false,
  }) async {
    final before = _pickedMedia;
    // A phone asks first: the WhatsApp browser opens the photo picker and has
    // no camera entry. A laptop opens its file dialog at once.
    var source = MediaSource.library;
    if (usesSourceSheet(defaultTargetPlatform)) {
      final choice = await showModalBottomSheet<MediaSource>(
        context: context,
        backgroundColor: const Color(0xFFF4F4F7),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) =>
            MediaSourceSheet(allowPhoto: !forceVideo, allowVideo: allowVideo),
      );
      if (choice == null) return;
      source = choice;
    }
    switch (source) {
      case MediaSource.camera:
        await _pickImage(ImageSource.camera);
      case MediaSource.video:
        await _pickVideo(ImageSource.camera);
      case MediaSource.library when forceVideo:
        await _pickVideo(ImageSource.gallery);
      case MediaSource.library when allowVideo:
        await _pickPhotoOrVideo();
      case MediaSource.library:
        await _pickImage(ImageSource.gallery);
    }
    // Design M-S-03: look at the new file before it is sent.
    if (mounted && _pickedMedia != null && !identical(_pickedMedia, before)) {
      await showDialog<void>(
        context: context,
        builder: (dialog) => Dialog.fullscreen(
          child: SubmissionConfirmDialog(
            bytes: _pickedMediaBytes,
            isVideo: _isVideoPick,
            onSend: () {
              Navigator.pop(dialog);
              _submitMedia(isVideo: _isVideoPick);
            },
            onChange: () {
              Navigator.pop(dialog);
              _chooseFile(allowVideo: allowVideo, forceVideo: forceVideo);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidedText = widget.message.data['guidedText'] as String?;
    final unguidedText = widget.message.data['unguidedText'] as String? ?? '';
    final validCriteria = widget.message.data['validCriteria'] as String?;
    final subTypes = widget.message.data['subTypes'] as String? ?? '';
    final kind = SubmissionKindResolver.fromSubTypes(subTypes);
    final stepNumber = widget.message.data['stepNumber'] as int?;
    final stepTotal = widget.message.data['stepTotal'] as int?;
    final isAwaiting = widget.controller.isAwaitingInput;
    final canInteract = isAwaiting && !_submitted;

    return ClassCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SubmissionChip(label: _kindLabel(kind)),
              // The design (M-S-01) has only the kind chip. "Step 1/1" says
              // nothing, so it shows only when there are several steps.
              if (stepNumber != null && stepTotal != null && stepTotal > 1)
                _SubmissionChip(
                  label: context.l10n.classStep(stepNumber, stepTotal),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _ExamplePreview(
            hasMedia: _pickedMedia != null,
            isVideo: _isVideoPick,
            mediaBytes: _pickedMediaBytes,
            onTap: canInteract && _isMediaKind(kind)
                ? () => _chooseFile(
                    allowVideo: kind != SubmissionKind.image,
                    forceVideo: kind == SubmissionKind.video,
                  )
                : _showSubmissionHelpDialog,
          ),
          const SizedBox(height: 14),
          Text(
            guidedText?.isNotEmpty == true ? guidedText! : unguidedText,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          if (unguidedText.isNotEmpty && guidedText?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              unguidedText,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.35,
                color: AppTheme.subheadingColor,
              ),
            ),
          ],
          if (validCriteria?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.classWillCheck(validCriteria!),
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.35,
                color: AppTheme.subheadingColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          if (_isMediaKind(kind)) ...[
            // Design M-S-01 and M-S-04: the real work of the others is in the
            // Gallery (R-85).
            FriendsMadeRow(onTap: () => context.go(AppRoutes.gallery)),
            const SizedBox(height: 12),
          ],
          if (_showFriendExamples(kind)) ...[
            Text(
              _friendLabel(kind),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subheadingColor,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_pickError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3C4BE)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppTheme.dangerText,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.classFileLoadFailed,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.dangerText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildInputForKind(kind, canInteract),
        ],
      ),
    );
  }

  Widget _buildInputForKind(SubmissionKind kind, bool canInteract) {
    switch (kind) {
      case SubmissionKind.emoji:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['👍', '👎', '😊', '😕', '💪', '🤔'].map((emoji) {
                final selected = _selectedEmoji == emoji;
                return InkWell(
                  onTap: canInteract
                      ? () => setState(() => _selectedEmoji = emoji)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.mutedLavender
                          : AppTheme.classroomMessageSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _submitRow(
              onPressed: (canInteract && _selectedEmoji != null)
                  ? () {
                      widget.controller.submitAssignmentAnswer(
                        SubmissionAnswer.emoji(_selectedEmoji!),
                      );
                      _markSubmitted();
                    }
                  : null,
            ),
          ],
        );

      case SubmissionKind.text:
        return _textSubmissionInput(
          canInteract: canInteract,
          hintText: context.l10n.classHintText,
          onSubmit: () {
            if (_textController.text.trim().isEmpty) return;
            widget.controller.submitAssignmentAnswer(
              SubmissionAnswer.text(_textController.text.trim()),
            );
            _markSubmitted();
          },
        );

      case SubmissionKind.textAudio:
      case SubmissionKind.audio:
        return _textSubmissionInput(
          canInteract: canInteract,
          hintText: context.l10n.classHintAudio,
          onSubmit: () {
            if (_textController.text.trim().isEmpty) return;
            widget.controller.submitAssignmentAnswer(
              SubmissionAnswer.audioTranscript(_textController.text.trim()),
            );
            _markSubmitted();
          },
        );

      case SubmissionKind.image:
        return _buildMediaPicker(
          canInteract: canInteract,
          allowVideo: false,
          onSubmit: () => _submitMedia(isVideo: false),
        );

      case SubmissionKind.video:
        return _buildMediaPicker(
          canInteract: canInteract,
          allowVideo: true,
          forceVideo: true,
          onSubmit: () => _submitMedia(isVideo: true),
        );

      case SubmissionKind.imageVideo:
        return _buildMediaPicker(
          canInteract: canInteract,
          allowVideo: true,
          onSubmit: () => _submitMedia(isVideo: _isVideoPick),
        );
    }
  }

  Widget _textSubmissionInput({
    required bool canInteract,
    required String hintText,
    required VoidCallback onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          enabled: canInteract,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _submitRow(onPressed: canInteract ? onSubmit : null),
      ],
    );
  }

  Widget _buildMediaPicker({
    required bool canInteract,
    required bool allowVideo,
    required VoidCallback onSubmit,
    bool forceVideo = false,
  }) {
    final hasMedia = _pickedMedia != null;
    void openPicker() =>
        _chooseFile(allowVideo: allowVideo, forceVideo: forceVideo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMedia) ...[
          InkWell(
            onTap: canInteract ? openPicker : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    _isVideoPick
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                    color: AppTheme.buttonColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pickedMedia!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.refresh_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        DashedUploadBox(
          error: _wrongFile,
          child: Column(
            children: [
              Icon(
                _wrongFile ? Icons.warning_amber_rounded : Icons.upload_rounded,
                size: 22,
                color: _wrongFile ? AppTheme.dangerText : AppTheme.buttonColor,
              ),
              const SizedBox(height: 8),
              if (_wrongFile) ...[
                Text(
                  forceVideo
                      ? context.l10n.classNotAVideo
                      : context.l10n.classNotAPhoto,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.dangerText,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              AppPrimaryButton(
                label: _submitted
                    ? context.l10n.classSent
                    : hasMedia
                    ? context.l10n.classShareSubmission
                    : context.l10n.classAddMyWork,
                loading: _isPicking,
                onPressed: !canInteract || _isPicking
                    ? null
                    : (hasMedia ? onSubmit : openPicker),
              ),
              const SizedBox(height: 8),
              Text(
                forceVideo
                    ? context.l10n.classVideoNeeded
                    : allowVideo
                    ? context.l10n.classPhotoOrVideoNeeded
                    : context.l10n.classPhotoNeeded,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.subheadingColor,
                ),
              ),
            ],
          ),
        ),
        // Design M-S-05: "Need help?" is outside the box, like "I'll do it later".
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AppTonalButton(
            label: context.l10n.classNeedHelp,
            onPressed: () => openAskTapFor(context, widget.controller),
          ),
        ),
        const SizedBox(height: 8),
        if (canInteract && !_isPicking)
          SizedBox(
            width: double.infinity,
            child: AppTonalButton(
              label: context.l10n.classDoLater,
              trailing: Icons.arrow_forward_rounded,
              onPressed: () {
                widget.controller.postponeSubmission();
                _markSubmitted();
              },
            ),
          ),
      ],
    );
  }

  Widget _submitRow({
    required VoidCallback? onPressed,
    String? primaryLabel,
    bool isLoading = false,
  }) => SubmitRow(
    label: _submitted
        ? context.l10n.classSent
        : (primaryLabel ?? context.l10n.classSubmit),
    isLoading: isLoading,
    onPressed: onPressed,
    onHelp: _showSubmissionHelpDialog,
  );

  bool _isMediaKind(SubmissionKind kind) =>
      kind == SubmissionKind.image ||
      kind == SubmissionKind.video ||
      kind == SubmissionKind.imageVideo;

  // The made-up "friends" rows are gone for photo and video: the Gallery shows
  // real work (R-85).
  bool _showFriendExamples(SubmissionKind kind) => kind == SubmissionKind.emoji;

  String _friendLabel(SubmissionKind kind) => switch (kind) {
    SubmissionKind.emoji => context.l10n.classFriendsSent,
    SubmissionKind.text ||
    SubmissionKind.textAudio ||
    SubmissionKind.audio => context.l10n.classFriendsSaid,
    _ => context.l10n.classSeeFriends,
  };

  String _kindLabel(SubmissionKind kind) => switch (kind) {
    SubmissionKind.emoji => context.l10n.classKindEmoji,
    SubmissionKind.text => context.l10n.classKindText,
    SubmissionKind.audio => context.l10n.classKindAudio,
    SubmissionKind.textAudio => context.l10n.classKindTextAudio,
    SubmissionKind.image => context.l10n.classKindPhoto,
    SubmissionKind.video => context.l10n.classKindVideo,
    SubmissionKind.imageVideo => context.l10n.classKindPhotoVideo,
  };

  Future<void> _showSubmissionHelpDialog() async {
    final guidedText = widget.message.data['guidedText'] as String?;
    final unguidedText = widget.message.data['unguidedText'] as String? ?? '';
    final validCriteria = widget.message.data['validCriteria'] as String?;
    final subTypes = widget.message.data['subTypes'] as String? ?? '';
    final kind = SubmissionKindResolver.fromSubTypes(subTypes);

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SubmissionHelpDialog(
            kindLabel: _kindLabel(kind),
            text: guidedText?.isNotEmpty == true ? guidedText! : unguidedText,
            validCriteria: validCriteria,
          ),
        ),
      ),
    );
  }
}

/// The content of "Submission Help". The chips wrap to a second line on a narrow
/// phone (they shared a row with the close X and ran past the edge), and the
/// whole content scrolls, so Continue can always be reached.
class SubmissionHelpDialog extends StatelessWidget {
  const SubmissionHelpDialog({
    super.key,
    required this.kindLabel,
    required this.text,
    required this.validCriteria,
  });

  final String kindLabel;
  final String text;
  final String? validCriteria;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SubmissionChip(
                      label: context.l10n.classTodaysActivity,
                      foregroundColor: AppTheme.buttonColor,
                    ),
                    _SubmissionChip(label: kindLabel),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              context.l10n.classHowToSubmit,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 34,
              color: AppTheme.imagePlaceholder,
            ),
          ),
          const SizedBox(height: 14),
          Text(text, style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
          if (validCriteria?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.classCheck(validCriteria!),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.subheadingColor,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: context.l10n.buttonContinue,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SubmissionChip extends StatelessWidget {
  const _SubmissionChip({
    required this.label,
    this.foregroundColor = AppTheme.textColor,
  });

  final String label;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _ExamplePreview extends StatelessWidget {
  const _ExamplePreview({
    required this.hasMedia,
    required this.isVideo,
    required this.mediaBytes,
    required this.onTap,
  });

  final bool hasMedia;
  final bool isVideo;
  final Uint8List? mediaBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: hasMedia
              ? (isVideo
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 54,
                          color: AppTheme.buttonColor,
                        ),
                      )
                    : mediaBytes != null
                    ? Image.memory(
                        mediaBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
              : const Icon(
                  Icons.image_outlined,
                  size: 34,
                  color: AppTheme.imagePlaceholder,
                ),
        ),
      ),
    );
  }
}

class ClassSubmissionReviewCard extends StatelessWidget {
  const ClassSubmissionReviewCard({required this.message, super.key});

  final ClassChatMessage message;

  @override
  Widget build(BuildContext context) {
    final feedback = message.data['feedback'] as String?;
    final score = message.data['score'] as int?;
    final passed = message.data['passed'] as bool?;
    final text = message.text ?? '';
    final failed = passed == false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: failed ? const Color(0xFFFFF1EF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: failed ? const Color(0xFFF3C4BE) : const Color(0xFFE0E2EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (failed) ...[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppTheme.dangerText,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: failed ? AppTheme.dangerText : AppTheme.textColor,
                  ),
                ),
              ),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: failed
                        ? const Color(0xFFF9D9D3)
                        : const Color(0xFFE7F7EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.classScore('$score'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: failed
                          ? AppTheme.dangerText
                          : AppTheme.successText,
                    ),
                  ),
                ),
            ],
          ),
          if (feedback != null && feedback.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              feedback,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.45,
                color: failed ? AppTheme.dangerText : AppTheme.subheadingColor,
              ),
            ),
          ],
          if (failed) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.classNoSubmissionPoints,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.dangerText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Congratulations card (design M-C19): the picture, "Congratulations
/// Aarav! 🥳", a "+25 points" pill and "You did a great job, champion!". There
/// is no button in it: the next bubble has the Continue.
class ClassSubmissionRewardCard extends StatelessWidget {
  const ClassSubmissionRewardCard({required this.message, super.key});

  final ClassChatMessage message;

  @override
  Widget build(BuildContext context) {
    final name = firstName(message.data['studentName'] as String? ?? '');
    final points = (message.data['points'] as num?)?.toInt() ?? 0;

    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/class-screen/Skill Passport 1.png',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.classCongratsName(name),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEBD2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8A33A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.classPointsPill(points),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF9A5B00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.classGreatJob,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.35,
              color: AppTheme.subheadingColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// The main button gets the full width and its label stays on one line (it
/// shrinks if needed). "Submission Help" sits below it. Before, both shared one
/// row and a long label wrapped and was cut off.
class SubmitRow extends StatelessWidget {
  const SubmitRow({
    super.key,
    required this.label,
    required this.onPressed,
    required this.onHelp,
    this.isLoading = false,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          label: label,
          loading: isLoading,
          onPressed: onPressed,
        ),
        TextButton(
          onPressed: onHelp,
          child: Text(
            context.l10n.classSubmissionHelp,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
