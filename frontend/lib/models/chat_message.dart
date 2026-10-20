import 'gemini_model_type.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final List<String> attachments;
  final DateTime timestamp;
  final bool isStreaming;
  final GeminiModelType? model;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.attachments = const [],
    required this.timestamp,
    this.isStreaming = false,
    this.model,
  });

  bool get isUser => role == 'user';
  bool get isModel => role == 'model';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    List<String>? attachments,
    DateTime? timestamp,
    bool? isStreaming,
    GeminiModelType? model,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      model: model ?? this.model,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'attachments': attachments,
      'timestamp': timestamp.toIso8601String(),
      'isStreaming': isStreaming,
      'model': model?.name,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['isStreaming'] as bool? ?? false,
      model: json['model'] != null
          ? GeminiModelType.fromString(json['model'] as String?)
          : null,
    );
  }
}
