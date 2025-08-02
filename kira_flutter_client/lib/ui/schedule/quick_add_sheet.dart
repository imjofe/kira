import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:provider/provider.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _titleController = TextEditingController();
  int _duration = 15;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          DropdownButton<int>(
            value: _duration,
            onChanged: (value) => setState(() => _duration = value!),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 min')),
              DropdownMenuItem(value: 15, child: Text('15 min')),
              DropdownMenuItem(value: 30, child: Text('30 min')),
              DropdownMenuItem(value: 60, child: Text('60 min')),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: implement createTask when backend is ready
              // provider.createTask(_titleController.text, _duration);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}