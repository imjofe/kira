import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          return Scaffold(
            body: SafeArea(
              child: Chat(
                user: const types.User(id: 'local_user'),
                messages: chat.messages,
                onSendPressed: (p) => chat.sendUserText(p.text),
                showUserAvatars: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
