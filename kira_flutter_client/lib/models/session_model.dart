import 'package:flutter/foundation.dart';

enum SessionStatus {
  pending,
  completed,
  skipped,
}

@immutable
class SessionModel {
  final int id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final SessionStatus status;

  const SessionModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  SessionModel copyWith({
    int? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
  }) {
    return SessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'status': status.name,
  };

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.pending,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      status.hashCode;

  @override
  String toString() => 'SessionModel(id: $id, title: $title, startTime: $startTime, endTime: $endTime, status: $status)';
}