import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final TaskDto task;

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'done':
        color = Colors.green;
        break;
      case 'skip':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }
    return Chip(label: Text(status), backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.25},
      background: Container(color: Colors.green, child: const Icon(Icons.check)),
      onDismissed: (_) => provider.updateStatus(task.id, 'done'),
      child: ListTile(
        leading: Text(DateFormat.Hm().format(task.start)),
        title: Text(task.title),
        trailing: _statusChip(task.status),
      ),
    );
  }
}