import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/features/chat/chat_screen.dart';
import 'package:kira_flutter_client/ui/chat/chat_provider.dart';
import 'package:kira_flutter_client/ui/schedule/quick_add_sheet.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/theme/app_theme.dart';

import 'quick_add_fab_opens_modal.mocks.dart';

@GenerateMocks([ChatProvider, ScheduleProvider])
void main() {
  testWidgets('FAB opens QuickAdd modal', (tester) async {
    // Create mock providers
    final mockChatProvider = MockChatProvider();
    final mockScheduleProvider = MockScheduleProvider();
    
    when(mockChatProvider.messages).thenReturn([]);
    when(mockChatProvider.isLoading).thenReturn(false);
    when(mockChatProvider.isTyping).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
          ChangeNotifierProvider<ScheduleProvider>.value(value: mockScheduleProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FAB is present
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    expect(find.text('Quick Add'), findsOneWidget);

    // Tap the FAB
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify that QuickAddSheet modal is shown
    expect(find.byType(QuickAddSheet), findsOneWidget);
    
    // Verify modal content
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    
    // Verify dropdown with duration options
    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('QuickAdd modal can be dismissed', (tester) async {
    // Create mock providers
    final mockChatProvider = MockChatProvider();
    final mockScheduleProvider = MockScheduleProvider();
    
    when(mockChatProvider.messages).thenReturn([]);
    when(mockChatProvider.isLoading).thenReturn(false);
    when(mockChatProvider.isTyping).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
          ChangeNotifierProvider<ScheduleProvider>.value(value: mockScheduleProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Container(
            decoration: const BoxDecoration(gradient: skyDawnGradient),
            child: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the FAB to open modal
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.byType(QuickAddSheet), findsOneWidget);

    // Tap the Save button to close modal
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify modal is closed
    expect(find.byType(QuickAddSheet), findsNothing);
  });
}