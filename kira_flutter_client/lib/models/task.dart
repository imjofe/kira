class Task {
  final String taskId;
  final String goalId;
  final String description;
  final String rrule;
  final int estimatedMinutes;

  Task({
    required this.taskId,
    required this.goalId,
    required this.description,
    required this.rrule,
    required this.estimatedMinutes,
  });

  Map<String, Object?> toMap() => {
    'task_id': taskId,
    'goal_id': goalId,
    'description': description,
    'rrule': rrule,
    'estimated_minutes': estimatedMinutes,
  };

  factory Task.fromMap(Map<String, Object?> m) => Task(
    taskId: m['task_id'] as String,
    goalId: m['goal_id'] as String,
    description: m['description'] as String,
    rrule: m['rrule'] as String,
    estimatedMinutes: m['estimated_minutes'] as int,
  );
}