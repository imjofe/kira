import 'package:meta/meta.dart';

@immutable
class MessageDto {
  final int id;
  final String role; // "user" or "assistant"
  final String content;
  final DateTime ts;

  const MessageDto({
    required this.id,
    required this.role,
    required this.content,
    required this.ts,
  });

  factory MessageDto.user(String text) {
    final now = DateTime.now();
    return MessageDto(
      id: now.microsecondsSinceEpoch,
      role: 'user',
      content: text,
      ts: now.toUtc(),
    );
  }

  factory MessageDto.assistant(String text) {
    final now = DateTime.now();
    return MessageDto(
      id: now.microsecondsSinceEpoch,
      role: 'assistant',
      content: text,
      ts: now.toUtc(),
    );
  }

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as int,
      role: json['role'] as String,
      content: json['content'] as String,
      ts: DateTime.parse(json['ts'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'ts': ts.toIso8601String(),
      };

  MessageDto copyWith({
    int? id,
    String? role,
    String? content,
    DateTime? ts,
  }) {
    return MessageDto(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      ts: ts ?? this.ts,
    );
  }
}
