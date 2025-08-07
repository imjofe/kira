import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key, this.testing = false}) : super(key: key);
  final bool testing;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.messages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Start the conversation…')),
      );
    }

    return Scaffold(
      key: testing ? const Key('chat_root') : null,
      body: Chat(
        messages: provider.messages
            .map<types.TextMessage>((m) => types.TextMessage(
                  author: types.User(id: m.role == 'user' ? 'me' : 'kira'),
                  createdAt: m.ts.millisecondsSinceEpoch,
                  id: m.id.toString(),
                  text: m.content,
                ))
            .toList(),
        onSendPressed: (p) => provider.send(p.text),
        user: const types.User(id: 'me'),
        showUserAvatars: !testing,
        showUserNames: !testing,
        typingIndicatorOptions: TypingIndicatorOptions(
          typingUsers: provider.isTyping
              ? [types.User(id: 'kira')]
              : const [],
        ),
        // The following are required by the chat UI but not used in this implementation.
        onAttachmentPressed: () {},
        onMessageTap: (context, message) {},
        onPreviewDataFetched: (message, previewData) {},
      ),
    );
  }
}
