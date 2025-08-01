import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/services/node_service.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_api.dart';

class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({this.testSeed});
  final List<TaskDto>? testSeed;

  final _today = <TaskDto>[];
  UnmodifiableListView<TaskDto> get tasks => UnmodifiableListView(_today);

  Future<void> fetchToday() async {
    if (testSeed != null) {
      _today
        ..clear()
        ..addAll(testSeed!);
      notifyListeners();
      return;
    }
    _today
      ..clear()
      ..addAll(await ScheduleApi.getToday());
    notifyListeners();
  }

  Future<void> updateStatus(int id, String status) async {
    final i = _today.indexWhere((t) => t.id == id);
    if (i != -1) {
      _today[i] = _today[i].copyWith(status: status);
      notifyListeners();
    }
    // fire-and-forget
    unawaited(NodeService.instance.sendFrame({
      'type': 'task.update',
      'payload': {'id': id, 'status': status}
    }));
  }
}