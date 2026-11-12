class ChatTurnModel {
  const ChatTurnModel({required this.role, required this.content});

  final String role;
  final String content;

  factory ChatTurnModel.user(String content) =>
      ChatTurnModel(role: 'user', content: content);
  factory ChatTurnModel.assistant(String content) =>
      ChatTurnModel(role: 'assistant', content: content);

  factory ChatTurnModel.fromJson(Map<String, dynamic> json) => ChatTurnModel(
    role: json['role'] as String? ?? 'user',
    content: json['content'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  static List<ChatTurnModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => ChatTurnModel.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToJson(List<ChatTurnModel> list) =>
      list.map((t) => t.toJson()).toList(growable: false);
}
