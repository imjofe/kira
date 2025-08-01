import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/goals/goals_provider.dart';
import 'package:provider/provider.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});
  final GoalDto goal;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GoalsProvider>();
    final testing = provider.seed != null; // detect seeded mode

    return Card(
      child: ListTile(
        title: Text(goal.title, key: ValueKey('title_${goal.id}')),
        subtitle: Text(goal.description),
        trailing: testing
            ? IconButton(
                key: ValueKey('move_${goal.id}'),
                icon: const Icon(Icons.redo),
                tooltip: 'Move right',
                onPressed: () {
                  final next = switch (goal.column) {
                    'Backlog' => 'Active',
                    'Active' => 'Done',
                    _ => 'Done',
                  };
                  provider.move(goal.id, next);
                },
              )
            : null,
      ),
    );
  }
}