import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kira_flutter_client/models/task_dto.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_provider.dart';
import 'package:kira_flutter_client/ui/calendar/task_list_sheet.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, this.testing = false});
  final bool testing;

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleProvider>();
    final cal = context.watch<CalendarProvider>();

    Map<DateTime, List<TaskDto>> _groupTasks() {
      final map = <DateTime, List<TaskDto>>{};
      for (final t in sched.tasks) {
        final d = DateTime(t.start.year, t.start.month, t.start.day);
        map.putIfAbsent(d, () => []).add(t);
      }
      return map;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: TableCalendar<TaskDto>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: cal.selected,
        selectedDayPredicate: (day) => isSameDay(day, cal.selected),
        calendarFormat: CalendarFormat.week,
        eventLoader: (day) =>
            _groupTasks()[DateTime(day.year, day.month, day.day)] ?? [],
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, _) {
            final key = testing
                ? Key('day_${DateFormat('yyyyMMdd').format(day)}')
                : null;
            return Container(
              key: key,
              alignment: Alignment.center,
              child: Text('${day.day}'),
            );
          },
        ),
        onDaySelected: (day, _) {
          cal.select(day);
          showModalBottomSheet(
            context: context,
            builder: (_) => ChangeNotifierProvider.value(
              value: sched,
              child: TaskListSheet(date: day),
            ),
          );
        },
      ),
    );
  }
}
