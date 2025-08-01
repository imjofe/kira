import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updateStatus sets task to done', () {
    // Mock the platform channel before the app is pumped.
    const MethodChannel('kira/node')
        .setMockMethodCallHandler((MethodCall methodCall) async => null);

    final p = ScheduleProvider(testMode: true);
    p.fetchToday(); // fake sync data
    expect(p.tasks.first.status, 'pending');
    p.updateStatus(p.tasks.first.id, 'done');
    expect(p.tasks.first.status, 'done');
  });
}