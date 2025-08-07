import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/bootstrap/kira_scaffold.dart';
import 'package:kira_flutter_client/features/onboarding/welcome_screen.dart';
import 'package:kira_flutter_client/features/chat/chat_screen.dart';
import 'package:kira_flutter_client/features/goals/goals_overview_screen.dart';
import 'package:kira_flutter_client/features/goals/goal_detail_screen.dart';
import 'package:kira_flutter_client/features/calendar/calendar_screen.dart';
import 'package:kira_flutter_client/shared/providers/settings_provider.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/ui/goals/goals_provider.dart';
import 'package:kira_flutter_client/services/websocket_service.dart';
import 'package:kira_flutter_client/llm/llama_bridge.dart';

GoRouter createRouter(SettingsProvider settingsProvider) {
  return GoRouter(
    initialLocation: settingsProvider.firstRunComplete ? '/schedule' : '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, __) => ChangeNotifierProvider(
          create: (_) => ChatProvider(
            ws: WebSocketService(),
            gemma: context.read<LlamaBridge>(),
          )..initCache(),
          child: const ChatScreen(),
        ),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, __) => ChangeNotifierProvider(
          create: (_) => GoalsProvider(gemma: context.read<LlamaBridge>()),
          child: const GoalsOverviewScreen(),
        ),
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (ctx, state) => ChangeNotifierProvider(
          create: (context) => GoalsProvider(gemma: context.read<LlamaBridge>()),
          child: GoalDetailScreen(goalId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, __) => ChangeNotifierProvider(
          create: (_) => ScheduleProvider(gemma: context.read<LlamaBridge>()),
          child: const CalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/', 
        redirect: (context, state) {
          final settings = context.read<SettingsProvider>();
          if (!settings.firstRunComplete) {
            return '/welcome';
          }
          return '/schedule';
        },
      ),
      GoRoute(
        path: '/:tab(schedule|goals|calendar|chat|settings)',
        builder: (ctx, state) {
          final tab = state.pathParameters['tab']!;
          if (tab == 'chat') {
            return ChangeNotifierProvider(
              create: (context) => ChatProvider(
                ws: WebSocketService(),
                gemma: context.read<LlamaBridge>(),
              )..initCache(),
              child: const ChatScreen(),
            );
          }
          return KiraScaffold(tab: tab);
        },
      ),
    ],
  );
}
