import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/goals/goals_provider.dart';
import 'package:provider/provider.dart';

class GoalEditDialog extends StatefulWidget {
  const GoalEditDialog({super.key});

  @override
  State<GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<GoalEditDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<GoalsProvider>().create(
                  _titleController.text,
                  _descriptionController.text,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
