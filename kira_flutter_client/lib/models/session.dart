class Session {
  final String sessionId;
  final String taskId;
  final String startTime;   // ISO-8601
  final String endTime;     // ISO-8601
  final String status;      // scheduled, completed, skipped, etc.

  Session({
    required this.sessionId,
    required this.taskId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  Map<String, Object?> toMap() => {
    'session_id': sessionId,
    'task_id': taskId,
    'start_time': startTime,
    'end_time': endTime,
    'status': status,
  };

  factory Session.fromMap(Map<String, Object?> m) => Session(
    sessionId: m['session_id'] as String,
    taskId: m['task_id'] as String,
    startTime: m['start_time'] as String,
    endTime: m['end_time'] as String,
    status: m['status'] as String,
  );
}