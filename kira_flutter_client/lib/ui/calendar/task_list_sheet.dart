import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class TaskListSheet extends StatelessWidget {
  const TaskListSheet({super.key, required this.date});
  final DateTime date;

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
    final tasks = context.watch<ScheduleProvider>().tasks.where((t) =>
        isSameDay(t.start, date)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: tasks
          .map((t) => ListTile(
                leading: Text(DateFormat.Hm().format(t.start)),
                title: Text(t.title),
                trailing: _statusChip(t.status),
              ))
          .toList(),
    );
  }
}
