import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final TaskDto task;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();

    return ListTile(
      key: ValueKey('task_${task.id}'),
      leading: Text(DateFormat.Hm().format(task.start)),
      title: Text(task.title),
      trailing: IconButton(
        key: ValueKey('done_${task.id}'),
        icon: Icon(
          task.status == 'done' ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.status == 'done' ? Colors.green : null,
        ),
        onPressed: () => provider.updateStatus(task.id, 'done'),
      ),
    );
  }
}
