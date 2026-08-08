/// Chat message model for the Research Q&A chat.
class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to OpenAI message format.
  Map<String, String> toApiMessage() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

enum MessageRole {
  user,
  assistant,
  system;
}
