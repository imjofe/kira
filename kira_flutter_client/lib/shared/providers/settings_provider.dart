import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _firstRunComplete = false;

  bool get firstRunComplete => _firstRunComplete;

  /// Sets the first run completion status and persists it
  Future<void> setFirstRunComplete(bool value) async {
    _firstRunComplete = value;
    notifyListeners();
    // TODO: Persist to SQLite key-value table when database layer is implemented
  }

  /// Loads settings from persistent storage
  Future<void> loadSettings() async {
    // TODO: Load from SQLite key-value table when database layer is implemented
    // For now, defaults to false
    _firstRunComplete = false;
    notifyListeners();
  }
}