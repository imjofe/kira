import 'package:flutter/material.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';

void main() {
  runApp(const KiraApp());
}

class KiraApp extends StatelessWidget {
  const KiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LLM Test'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Gemma3n.run('2+2=');
              print('LLM Result: $result');
            },
            child: const Text('Run LLM'),
          ),
        ),
      ),
    );
  }
}
