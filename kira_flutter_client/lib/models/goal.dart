class Goal {
  final String goalId;
  final String type;           // fitness, skill, project, other
  final String description;
  final String? deadline;      // ISO-8601 or null

  Goal({required this.goalId, required this.type, required this.description, this.deadline});

  Map<String, Object?> toMap() => {
    'goal_id': goalId,
    'type': type,
    'description': description,
    'deadline': deadline,
  };

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
    goalId: m['goal_id'] as String,
    type: m['type'] as String,
    description: m['description'] as String,
    deadline: m['deadline'] as String?,
  );
}