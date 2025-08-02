import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/schedule/quick_add_sheet.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/ui/schedule/task_card.dart';
import 'package:provider/provider.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider()..fetchToday(),
      child: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          final tasks = provider.tasks;
          return Scaffold(
            appBar: AppBar(title: const Text('Today')),
            body: RefreshIndicator(
              onRefresh: provider.fetchToday,
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (_, i) => TaskCard(task: tasks[i]),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const QuickAddSheet(),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
