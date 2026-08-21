import 'package:flutter/widgets.dart';

class OnboardingMessage {
  const OnboardingMessage({
    required this.isBot,
    required this.text,
    this.content,
    this.hasVoice = false,
  });

  final bool isBot;
  final String text;
  final Widget? content;
  final bool hasVoice;

  String get sender => isBot ? 'bot' : 'user';
  Widget? get customContent => content;
}

class LearningTrackOption {
  const LearningTrackOption({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
  });

  final String id;
  final String label;
  final String description;
  final String emoji;
}

const learningTrackOptions = <LearningTrackOption>[
  LearningTrackOption(
    id: 'science-lab',
    label: 'Science Lab',
    description: 'Hands-on electronics and experiments',
    emoji: '🔬',
  ),
  LearningTrackOption(
    id: 'coding',
    label: 'Coding',
    description: 'Build games and apps step by step',
    emoji: '💻',
  ),
  LearningTrackOption(
    id: 'financial-literacy',
    label: 'Financial Literacy',
    description: 'Learn how money really works',
    emoji: '📈',
  ),
  LearningTrackOption(
    id: 'arts',
    label: 'Visual Arts',
    description: 'Sketch, paint, and express yourself',
    emoji: '🎨',
  ),
];

String learningTrackLabel(String? trackId) {
  for (final option in learningTrackOptions) {
    if (option.id == trackId) return option.label;
  }
  return trackId ?? '';
}
