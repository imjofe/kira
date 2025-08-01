import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/services/node_service.dart';

class GoalDto {
  final int id;
  final String title;
  final String description;
  final String column; // Backlog | Active | Done

  GoalDto({
    required this.id,
    required this.title,
    required this.description,
    required this.column,
  });

  GoalDto copyWith({String? column}) => GoalDto(
        id: id,
        title: title,
        description: description,
        column: column ?? this.column,
      );
}

class GoalsProvider extends ChangeNotifier {
  GoalsProvider({this.seed});
  final List<GoalDto>? seed;

  final _goals = <GoalDto>[];
  UnmodifiableListView<GoalDto> get backlog =>
      UnmodifiableListView(_goals.where((g) => g.column == 'Backlog'));
  UnmodifiableListView<GoalDto> get active =>
      UnmodifiableListView(_goals.where((g) => g.column == 'Active'));
  UnmodifiableListView<GoalDto> get done =>
      UnmodifiableListView(_goals.where((g) => g.column == 'Done'));

  Future<void> fetch() async {
    if (seed != null) {
      _goals
        ..clear()
        ..addAll(seed!);
      notifyListeners();
      return;
    }
    // _goals
    //   ..clear()
    //   ..addAll(await GoalsApi.getAll()); // TODO Contract B
    notifyListeners();
  }

  Future<void> move(int id, String to) async {
    final i = _goals.indexWhere((g) => g.id == id);
    if (i != -1) _goals[i] = _goals[i].copyWith(column: to);
    notifyListeners();
    unawaited(NodeService.instance.sendFrame({
      'type': 'goal.move',
      'payload': {'id': id, 'to': to}
    }));
  }

  Future<void> create(String title, String desc) async {
    final tmpId = DateTime.now().millisecondsSinceEpoch;
    _goals.add(GoalDto(id: tmpId, title: title, description: desc, column: 'Backlog'));
    notifyListeners();
    unawaited(NodeService.instance.sendFrame({
      'type': 'goal.create',
      'payload': {'title': title, 'description': desc}
    }));
  }
}