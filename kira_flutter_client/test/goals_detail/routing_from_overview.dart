import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goal_detail_screen.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('routing to /goals/1 builds GoalDetailScreen with goalId 1', (tester) async {
    GoalDetailScreen? capturedScreen;
    final router = GoRouter(
      initialLocation: '/goals/1',
      routes: [
        GoRoute(
          path: '/goals/:id',
          builder: (context, state) {
            final goalId = int.parse(state.pathParameters['id']!);
            final screen = GoalDetailScreen(goalId: goalId);
            capturedScreen = screen;
            return ChangeNotifierProvider(
              create: (_) => GoalsProvider(),
              child: screen,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    // Verify that GoalDetailScreen was built
    expect(find.byType(GoalDetailScreen), findsOneWidget);
    
    // Verify that the screen was created with the correct goalId
    expect(capturedScreen, isNotNull);
    expect(capturedScreen!.goalId, equals(1));
  });

  testWidgets('routing to /goals/42 builds GoalDetailScreen with goalId 42', (tester) async {
    GoalDetailScreen? capturedScreen;
    final router = GoRouter(
      initialLocation: '/goals/42',
      routes: [
        GoRoute(
          path: '/goals/:id',
          builder: (context, state) {
            final goalId = int.parse(state.pathParameters['id']!);
            final screen = GoalDetailScreen(goalId: goalId);
            capturedScreen = screen;
            return ChangeNotifierProvider(
              create: (_) => GoalsProvider(),
              child: screen,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();

    // Verify that GoalDetailScreen was built
    expect(find.byType(GoalDetailScreen), findsOneWidget);
    
    // Verify that the screen was created with the correct goalId
    expect(capturedScreen, isNotNull);
    expect(capturedScreen!.goalId, equals(42));
  });
}