import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_page.dart';
import 'package:kira_flutter_client/ui/goals/goals_page.dart';
import 'package:kira_flutter_client/ui/calendar/calendar_page.dart';
import 'package:kira_flutter_client/ui/chat/chat_page.dart';
import 'package:kira_flutter_client/ui/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';

class KiraScaffold extends StatefulWidget {
  const KiraScaffold({super.key, required this.tab});
  final String tab;

  @override
  State<KiraScaffold> createState() => _KiraScaffoldState();
}

class _KiraScaffoldState extends State<KiraScaffold> {
  static const _tabs = ['schedule', 'goals', 'calendar', 'chat', 'settings'];

  int get _index => _tabs.indexOf(widget.tab);

  void _go(int i) => context.go('/${_tabs[i]}');

  @override
  Widget build(BuildContext context) {
    final navRail = NavigationRail(
      selectedIndex: _index,
      onDestinationSelected: _go,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.today), label: Text('Today')),
        NavigationRailDestination(icon: Icon(Icons.track_changes), label: Text('Goals')),
        NavigationRailDestination(icon: Icon(Icons.calendar_view_week), label: Text('Calendar')),
        NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), label: Text('Chat')),
        NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
      ],
    );

    final bottomNav = BottomNavigationBar(
      currentIndex: _index,
      onTap: _go,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Goals'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );

    final body = IndexedStack(
      index: _index,
      children: [
        const SchedulePage(),
        const GoalsPage(),
        const CalendarPage(),
        // Hot-reload note: If ProviderNotFound error, hot-restart app.
        ChangeNotifierProvider(
          create: (context) => ChatProvider(
            ws: WebSocketService(),
            gemma: context.read<LlamaBridge>(),
          )..initCache(),
          child: const ChatPage(),
        ),
        const SettingsPage(),
      ],
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return Scaffold(
          body: Row(
            children: [
              if (isWide) navRail,
              Expanded(child: body),
            ],
          ),
          bottomNavigationBar: isWide ? null : bottomNav,
        );
      },
    );
  }
}