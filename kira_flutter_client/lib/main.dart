import 'package:flutter/material.dart';
import 'package:kira_flutter_client/app.dart';

void main() {
  print('[MAIN] Starting Kira app...');
  WidgetsFlutterBinding.ensureInitialized();
  print('[MAIN] Flutter binding initialized');
  // If hot-reloading causes 'Provider not found', do a full hot-restart.
  print('[MAIN] About to run KiraApp...');
  runApp(const KiraApp());
  print('[MAIN] runApp called');
}
