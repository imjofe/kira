import 'package:kira_flutter_client/models/task_dto.dart';

class ScheduleApi {
  static Future<List<TaskDto>> getToday() async => [
        TaskDto(
          id: 1,
          title: 'Morning stretch',
          start: DateTime.now(),
          duration: 10,
          status: 'pending',
        ),
        TaskDto(
          id: 2,
          title: 'Team standup',
          start: DateTime.now().add(const Duration(hours: 1)),
          duration: 15,
          status: 'pending',
        ),
        TaskDto(
          id: 3,
          title: 'Work on FL-10',
          start: DateTime.now().add(const Duration(hours: 2)),
          duration: 90,
          status: 'pending',
        ),
      ];

  static List<TaskDto> fakeToday() => [
        TaskDto(id: 1, title: 'Mock task', start: DateTime.now(), duration: 10, status: 'pending'),
      ];
}
