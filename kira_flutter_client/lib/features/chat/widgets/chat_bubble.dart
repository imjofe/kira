import 'package:flutter/material.dart';
import 'package:kira_flutter_client/ui/chat/message_dto.dart';

class ChatBubble extends StatelessWidget {
  final MessageDto msg;
  
  const ChatBubble({super.key, required this.msg});

  bool get isUser => msg.role == 'user';

  @override
  Widget build(BuildContext context) => Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isUser ? Colors.white : Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(msg.content, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}