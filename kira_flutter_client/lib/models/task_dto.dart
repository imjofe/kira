import 'package:flutter/foundation.dart';

@immutable
class TaskDto {
  final int id;
  final String title;
  final DateTime start;
  final int duration;
  final String status;

  const TaskDto({
    required this.id,
    required this.title,
    required this.start,
    required this.duration,
    required this.status,
  });

  TaskDto copyWith({
    int? id,
    String? title,
    DateTime? start,
    int? duration,
    String? status,
  }) {
    return TaskDto(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }
}
