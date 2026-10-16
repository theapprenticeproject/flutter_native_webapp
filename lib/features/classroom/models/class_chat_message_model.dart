enum ClassChatSender { bot, user }

enum ClassChatContentType {
  text,
  checkpoint,
  video,
  submission,

  submissionAnswerEcho,
  submissionReviewing,
  submissionReview,
  submissionReward,
  quizQuestion,
  quizAnswerEcho,
  quizFeedback,
  quizSummary,
  unitTransition,
  sessionEnd,
  weeklyCapReached,
  errorRetry,
  loading,
}

class ClassChatMessage {
  const ClassChatMessage({
    required this.id,
    required this.stepId,
    required this.sender,
    required this.contentType,
    this.text,
    this.data = const {},
    this.isPending = false,
  });

  final String id;
  final String stepId;
  final ClassChatSender sender;
  final ClassChatContentType contentType;
  final String? text;
  final Map<String, dynamic> data;
  final bool isPending;

  ClassChatMessage copyWith({
    Map<String, dynamic>? data,
    bool? isPending,
    String? text,
  }) => ClassChatMessage(
    id: id,
    stepId: stepId,
    sender: sender,
    contentType: contentType,
    text: text ?? this.text,
    data: data ?? this.data,
    isPending: isPending ?? this.isPending,
  );
}
