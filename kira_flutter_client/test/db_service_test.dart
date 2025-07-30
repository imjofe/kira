import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kira_flutter_client/services/db_service.dart';
import 'package:kira_flutter_client/models/session.dart';

void main() {
  // Let sqflite use its FFI implementation with the bundled binary.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the path_provider platform channel
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      return '.'; // Use the current directory for testing
    }
    return null;
  });

  test('DbService CRUD operations work correctly', () async {
    final db = DbService();
    final s = Session(
      sessionId: 'sid-test',
      taskId: 'tid-1',
      startTime: '2025-08-01T09:00:00-05:00',
      endTime: '2025-08-01T10:00:00-05:00',
      status: 'scheduled',
    );
    await db.insertSessions([s]);
    final rows = await db.upcomingSessions();
    expect(rows.where((e) => e.sessionId == 'sid-test').length, 1);
  });
}
