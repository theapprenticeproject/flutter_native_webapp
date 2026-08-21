import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/class_chat_message_model.dart';
import '../../../models/submission_answer_model.dart';
import '../../../providers/class_chat_controller.dart';
import 'class_card_shell.dart';

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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _markSubmitted() {
    setState(() => _submitted = true);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPicking = true;
      _pickError = false;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
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
          const SnackBar(
            content: Text("Couldn't access that. Please try again."),
          ),
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
    });
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (file != null) {
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
          const SnackBar(
            content: Text("Couldn't access that. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _showMediaSourceSheet({
    required bool allowVideo,
    bool forceVideo = false,
  }) async {
    final choice = await showModalBottomSheet<_MediaPickChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (!forceVideo) ...[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () =>
                    Navigator.pop(context, _MediaPickChoice.cameraImage),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose photo from gallery'),
                onTap: () =>
                    Navigator.pop(context, _MediaPickChoice.galleryImage),
              ),
            ],
            if (allowVideo) ...[
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Record a video'),
                onTap: () =>
                    Navigator.pop(context, _MediaPickChoice.cameraVideo),
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Choose video from gallery'),
                onTap: () =>
                    Navigator.pop(context, _MediaPickChoice.galleryVideo),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    switch (choice) {
      case _MediaPickChoice.cameraImage:
        await _pickImage(ImageSource.camera);
        break;
      case _MediaPickChoice.galleryImage:
        await _pickImage(ImageSource.gallery);
        break;
      case _MediaPickChoice.cameraVideo:
        await _pickVideo(ImageSource.camera);
        break;
      case _MediaPickChoice.galleryVideo:
        await _pickVideo(ImageSource.gallery);
        break;
      case null:
        break;
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
              _SubmissionChip(
                label: "TODAY'S ACTIVITY 🏎️🏎️",
                foregroundColor: AppTheme.buttonColor,
              ),
              _SubmissionChip(label: _kindLabel(kind)),
              if (stepNumber != null && stepTotal != null)
                _SubmissionChip(label: 'STEP $stepNumber/$stepTotal'),
            ],
          ),
          const SizedBox(height: 12),
          _ExamplePreview(
            hasMedia: _pickedMedia != null,
            isVideo: _isVideoPick,
            mediaBytes: _pickedMediaBytes,
            onTap: canInteract && _isMediaKind(kind)
                ? () => _showMediaSourceSheet(
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
              'I will check for: $validCriteria',
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
                        "We couldn't load that file. Please try picking it again.",
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
          hintText: 'Type your answer here...',
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
          hintText: 'Type or transcribe your answer here...',
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
          onSubmit: () {
            if (_pickedMedia == null) return;
            widget.controller.submitAssignmentAnswer(
              SubmissionAnswer.image(_pickedMedia!.path),
            );
            _markSubmitted();
          },
        );

      case SubmissionKind.video:
        return _buildMediaPicker(
          canInteract: canInteract,
          allowVideo: true,
          forceVideo: true,
          onSubmit: () {
            if (_pickedMedia == null) return;
            widget.controller.submitAssignmentAnswer(
              SubmissionAnswer.video(_pickedMedia!.path),
            );
            _markSubmitted();
          },
        );

      case SubmissionKind.imageVideo:
        return _buildMediaPicker(
          canInteract: canInteract,
          allowVideo: true,
          onSubmit: () {
            if (_pickedMedia == null) return;
            widget.controller.submitAssignmentAnswer(
              SubmissionAnswer.imageOrVideo(
                _pickedMedia!.path,
                isVideo: _isVideoPick,
              ),
            );
            _markSubmitted();
          },
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
        _showMediaSourceSheet(allowVideo: allowVideo, forceVideo: forceVideo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _mediaFriendExamples(forceVideo: forceVideo)
              .map(
                (emoji) => _FriendExampleTile(
                  label: emoji,
                  selected: false,
                  onTap: canInteract ? openPicker : null,
                ),
              )
              .toList(),
        ),
        if (hasMedia) ...[
          const SizedBox(height: 12),
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
        _submitRow(
          primaryLabel: hasMedia ? 'Share submission' : 'Submit',
          isLoading: _isPicking,
          onPressed: !canInteract || _isPicking
              ? null
              : (hasMedia ? onSubmit : openPicker),
        ),
      ],
    );
  }

  Widget _submitRow({
    required VoidCallback? onPressed,
    String primaryLabel = 'Submit',
    bool isLoading = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.dividerColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_submitted ? 'Sent' : primaryLabel),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: _showSubmissionHelpDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.subheadingColor,
              side: const BorderSide(color: AppTheme.dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Submission Help'),
          ),
        ),
      ],
    );
  }

  bool _isMediaKind(SubmissionKind kind) =>
      kind == SubmissionKind.image ||
      kind == SubmissionKind.video ||
      kind == SubmissionKind.imageVideo;

  bool _showFriendExamples(SubmissionKind kind) =>
      kind == SubmissionKind.emoji || _isMediaKind(kind);

  String _friendLabel(SubmissionKind kind) => switch (kind) {
    SubmissionKind.emoji => 'Friends sent 👀',
    SubmissionKind.text ||
    SubmissionKind.textAudio ||
    SubmissionKind.audio => 'Friends said 👀',
    _ => 'See what friends made 👀',
  };

  List<String> _mediaFriendExamples({required bool forceVideo}) =>
      forceVideo ? const ['🎥', '🎬', '🚀'] : const ['🐱', '🚀', '🌈'];

  String _kindLabel(SubmissionKind kind) => switch (kind) {
    SubmissionKind.emoji => '👉 EMOJI',
    SubmissionKind.text => '💬 TEXT',
    SubmissionKind.audio => '🎤 AUDIO',
    SubmissionKind.textAudio => '💬 TEXT / 🎤 AUDIO',
    SubmissionKind.image => '🖼️ SCREENSHOT',
    SubmissionKind.video => '🎥 VIDEO',
    SubmissionKind.imageVideo => '🖼️ SCREENSHOT / 🎥 VIDEO',
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
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SubmissionChip(
                      label: "TODAY'S ACTIVITY 🏎️🏎️",
                      foregroundColor: AppTheme.buttonColor,
                    ),
                    const SizedBox(width: 8),
                    _SubmissionChip(label: _kindLabel(kind)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'How to submit',
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
                Text(
                  guidedText?.isNotEmpty == true ? guidedText! : unguidedText,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                ),
                if (validCriteria?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Check: $validCriteria',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.subheadingColor,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _MediaPickChoice { cameraImage, galleryImage, cameraVideo, galleryVideo }

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

class _FriendExampleTile extends StatelessWidget {
  const _FriendExampleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 68,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.mutedLavender : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.buttonColor : AppTheme.borderColor,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 22)),
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
                    'Score: $score',
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
              'No submission points were added for this attempt.',
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

class ClassSubmissionRewardCard extends StatelessWidget {
  const ClassSubmissionRewardCard({
    required this.message,
    required this.controller,
    super.key,
  });

  final ClassChatMessage message;
  final ClassChatController controller;

  @override
  Widget build(BuildContext context) {
    final studentName = message.data['studentName'] as String? ?? 'Champ';
    final points = (message.data['points'] as num?)?.toInt() ?? 0;

    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppTheme.classroomMessageSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.volume_up_rounded,
              size: 18,
              color: AppTheme.buttonColor,
            ),
          ),
          Image.asset(
            'assets/class-screen/Skill Passport 1.png',
            height: 235,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            'Congratulations $studentName!!!🥳',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3A72C),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '⊙ +$points pts',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You have won $points points🪙😍\nYou did a great job champion!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.35,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: controller.continueAfterSubmissionReward,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
