import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/goals/goals_overview_screen.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

void main() {
  testWidgets('goal card navigates to detail page', (tester) async {
    // Create provider with test goals
    final goalsProvider = GoalsProvider();
    final goals = [
      const GoalModel(
        id: 1,
        title: 'Test Goal',
        subtitle: 'Test subtitle',
        targetTime: TimeOfDay(hour: 1, minute: 0),
      ),
    ];
    goalsProvider.initWithSeed(goals);

    // Track navigation
    String? currentLocation;
    final router = GoRouter(
      initialLocation: '/goals',
      routes: [
        GoRoute(
          path: '/goals',
          builder: (_, __) => ChangeNotifierProvider.value(
            value: goalsProvider,
            child: const GoalsOverviewScreen(),
          ),
        ),
        GoRoute(
          path: '/goals/:id',
          builder: (_, state) {
            currentLocation = '/goals/${state.pathParameters['id']}';
            return const Scaffold(body: Text('Goal Detail'));
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

    // Find and tap the first goal card
    final goalCard = find.text('Test Goal');
    expect(goalCard, findsOneWidget);
    
    await tester.tap(goalCard);
    await tester.pumpAndSettle();

    // Verify navigation to the correct route
    expect(currentLocation, equals('/goals/1'));
    expect(find.text('Goal Detail'), findsOneWidget);
  });
}