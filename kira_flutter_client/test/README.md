# Kira Flutter Client Tests

This directory contains all tests for the Kira Flutter client application.

## Test Structure

### Core Tests
- **`prompt_builder_test.dart`** - Comprehensive tests for the PromptBuilder utility (consolidated from multiple files)
- **`global_prompt_test.dart`** - Tests for the global system prompt (checksum and size constraints)
- **`slash_router_test.dart`** - Tests for slash command parsing and routing
- **`websocket_service_test.dart`** - Tests for WebSocket service functionality

### UI Tests
- **`chat/`** - Chat-related UI tests
  - `chat_provider_test.dart` - ChatProvider business logic tests
  - `chat_page_test.dart` - ChatPage widget interaction tests
- **`calendar_tests.dart`** - Calendar page widget tests
- **`goals_tests.dart`** - Goals page and provider tests
- **`schedule_tests.dart`** - Schedule page and task card tests

### Integration Tests
- **`provider_prompt_integration_test.dart`** - Integration tests between ChatProvider and PromptBuilder

### Unit Tests
- **`unit/schedule_provider_test.dart`** - Unit tests for ScheduleProvider

### Test Data
- **`goldens/`** - Golden test data for prompt builder tests
  - `minimal.json` - Minimal prompt test data
  - `mode_json.json` - JSON mode test data

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test File
```bash
flutter test test/prompt_builder_test.dart
```

### With Verbose Output
```bash
flutter test --verbose
```

### Using Test Runner Script
```bash
./run_tests.sh
```

## Test Organization

The tests are organized by:
1. **Core utilities** - PromptBuilder, SlashRouter, WebSocketService
2. **UI components** - Pages and widgets with their providers
3. **Integration** - Cross-component functionality
4. **Unit tests** - Isolated business logic

## Mocking Strategy

All tests use **Mocktail** for mocking dependencies. This provides a consistent and type-safe mocking experience across all test files.

## Dependencies

Test dependencies are defined in `pubspec.yaml`:
- `flutter_test` - Flutter testing framework
- `mocktail` - Mocking library
- `crypto` - For checksum tests
- `test` - General testing utilities

## Cleanup Summary

The test folder has been cleaned up by:
1. ✅ Removed duplicate `prompt_builder_golden_test..dart` file
2. ✅ Consolidated multiple prompt builder tests into a single comprehensive file
3. ✅ Fixed import paths in chat provider tests
4. ✅ Updated mocking library usage to be consistent (Mocktail)
5. ✅ Fixed string escaping issues
6. ✅ Added missing dependencies (crypto)
7. ✅ Fixed mock setup for WebSocket service tests

All tests now pass successfully! 🎉 