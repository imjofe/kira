import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/onboarding/welcome_screen.dart';
import 'package:kira_flutter_client/shared/providers/settings_provider.dart';
import 'package:kira_flutter_client/shared/services/notification_agent.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'welcome_completes_first_run.mocks.dart';

@GenerateMocks([SettingsProvider])
void main() {
  testWidgets('welcome screen completes first run', (tester) async {
    // Create a mock settings provider
    final mockSettingsProvider = MockSettingsProvider();
    when(mockSettingsProvider.firstRunComplete).thenReturn(false);
    when(mockSettingsProvider.setFirstRunComplete(any))
        .thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (_, __) => const Scaffold(body: Text('Chat Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      NotificationAgent(
        child: ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap the "Ready to start?" button
    final buttonFinder = find.text('Ready to start?');
    expect(buttonFinder, findsOneWidget);
    
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Verify setFirstRunComplete(true) was called once
    verify(mockSettingsProvider.setFirstRunComplete(true)).called(1);

    // Verify navigation to /chat
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/chat');
  });
}