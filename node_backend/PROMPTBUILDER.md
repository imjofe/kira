# PromptBuilder Implementation

This document describes the shared PromptBuilder implementation for the Node.js backend that matches the Flutter client's prompt assembly logic.

## Files

- **`src/prompts/globalPrompt.js`** - Global system prompt constant
- **`src/utils/promptBuilder.js`** - Main PromptBuilder implementation  
- **`__tests__/promptBuilder.test.js`** - Comprehensive test suite

## Usage

```javascript
import { buildPrompt } from "./src/utils/promptBuilder.js";

// Basic chat scenario
const envelope = buildPrompt({
  l1Persona: "<<MODULE:CHAT>> You are a helpful assistant.",
  userInput: "Hello, how are you?"
});

// With memory context
const envelopeWithMemory = buildPrompt({
  l1Persona: "<<MODULE:CHAT>> You are a helpful assistant.",
  userInput: "What did we discuss earlier?",
  memory: ["We talked about JavaScript", "You asked about async/await"]
});

// JSON mode with ephemeral message
const jsonEnvelope = buildPrompt({
  l1Persona: "<<MODULE:QuickAdd>> Return JSON only.",
  userInput: "Schedule a meeting tomorrow",
  requireJson: true,
  l3Ephemeral: "/mode=json"
});
```

## Features

✅ **Identical prompt structure** to Flutter client  
✅ **Memory window limiting** (20 items max)  
✅ **String truncation** (16KB per string max)  
✅ **Size guard** (64KB envelope max in development)  
✅ **Production optimization** (size guard disabled)  
✅ **ES module support** with Node.js  
✅ **Comprehensive test coverage** (6 test cases)

## API

### `buildPrompt(options)`

**Parameters:**
- `l1Persona` (string) - Required. Module-specific persona prompt
- `userInput` (string) - Required. User's input message
- `memory` (string[]) - Optional. Array of previous assistant responses
- `l3Ephemeral` (string|null) - Optional. Ephemeral system message
- `requireJson` (boolean) - Optional. Whether response must be JSON

**Returns:** Object with `messages` array and `metadata` object

**Envelope Structure:**
```javascript
{
  "messages": [
    { "role": "system", "content": "Global system prompt..." },
    { "role": "system", "content": "L1 persona prompt" },
    // Memory messages (role: "assistant")
    { "role": "user", "content": "User input" },
    // Optional ephemeral message
  ],
  "metadata": {
    "prompt_version": "1.1",
    "require_json": false
  }
}
```

## Testing

Run tests with:
```bash
npm test
```

Test coverage includes:
- Basic envelope creation
- Memory truncation to 20 items
- Ephemeral message inclusion
- JSON flag setting
- Size guard in development
- Size guard bypass in production

## Implementation Notes

- Uses ES modules (`import`/`export`)
- Memory window keeps last 20 items only
- Individual strings truncated to 16KB
- Envelope size checked in development mode only
- Buffer.byteLength() used for accurate UTF-8 byte counting
- Consistent with Flutter client PromptBuilder v1.1

## Performance

- Minimal runtime dependencies (Node.js stdlib only)
- Optimized for nodejs-mobile embedded environment
- Production builds skip size validation for performance