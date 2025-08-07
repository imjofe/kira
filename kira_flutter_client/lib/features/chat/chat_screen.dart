import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/quickadd/quickadd_provider.dart';
import 'package:kira_flutter_client/features/chat/widgets/chat_bubble.dart';
import 'package:kira_flutter_client/features/chat/widgets/dots_typing.dart';
import 'package:kira_flutter_client/features/chat/widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          // Auto-scroll to bottom when messages change
          if (provider.messages.isNotEmpty) {
            _scrollToBottom();
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.messages.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Text(
                      'Start the conversation…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                ChatInputBar(onSend: provider.send),
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.messages.length,
                  itemBuilder: (context, i) => ChatBubble(msg: provider.messages[i]),
                ),
              ),
              if (provider.isTyping) const DotsTyping(),
              ChatInputBar(onSend: provider.send),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddProvider.openModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black87,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}