import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/goals/goal_card.dart';
import 'package:kira_flutter_client/ui/goals/goal_edit_dialog.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:kira_flutter_client/ui/goals/goals_provider.dart';
import 'package:provider/provider.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoalsProvider(gemma: context.read<LlamaBridge>())..fetch(),
      child: Consumer<GoalsProvider>(
        builder: (context, p, child) {
          Widget buildColumn(String title, List<GoalDto> items) => Expanded(
                child: DragTarget<int>(
                  onAccept: (id) => p.move(id, title),
                  builder: (_, __, ___) => Column(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Expanded(
                        child: ListView(
                          children: items
                              .map((g) => Draggable<int>(
                                    data: g.id,
                                    feedback: Material(
                                      child: GoalCard(goal: g),
                                    ),
                                    child: GoalCard(goal: g),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );

          return Scaffold(
            appBar: AppBar(title: const Text('Goals')),
            body: Row(
              children: [
                buildColumn('Backlog', p.backlog),
                buildColumn('Active', p.active),
                buildColumn('Done', p.done),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: p,
                  child: const GoalEditDialog(),
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