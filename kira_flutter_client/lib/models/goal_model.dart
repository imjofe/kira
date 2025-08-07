import 'package:flutter/material.dart';

class GoalModel {
  final int id;
  final String title;
  final String subtitle;
  final TimeOfDay targetTime;

  const GoalModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetTime,
  });

  GoalModel copyWith({
    int? id,
    String? title,
    String? subtitle,
    TimeOfDay? targetTime,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      targetTime: targetTime ?? this.targetTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'targetTime': '${targetTime.hour}:${targetTime.minute}',
  };

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final timeStr = json['targetTime'] as String;
    final timeParts = timeStr.split(':');
    return GoalModel(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      targetTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );
  }
}