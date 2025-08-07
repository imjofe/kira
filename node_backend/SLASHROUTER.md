# Slash-Command Whitelist Middleware

This document describes the slash-command whitelist middleware that provides runtime security for the Node.js orchestrator by rejecting non-approved `/commands`.

## Files

- **`src/middleware/slashRouter.js`** - Main middleware implementation
- **`__tests__/slashRouter.test.js`** - Comprehensive test suite (9 test cases)

## Whitelist

The following slash commands are approved and will pass validation:

- **`/mode=json`** - Switch to JSON-only response mode
- **`/debug`** - Enable debug output
- **`/summarize`** - Request content summarization
- **`/sql`** - SQL-related operations
- **`/rephrase`** - Request content rephrasing

All other slash commands will be **rejected** and return `null`.

## API

### `parseSlashCommand(text)`

Direct validation function for slash commands.

**Parameters:**
- `text` (string) - Raw message content to validate

**Returns:**
- Original string if command is whitelisted
- `null` if command is not approved

**Example:**
```javascript
import { parseSlashCommand } from "./src/middleware/slashRouter.js";

const result1 = parseSlashCommand("/debug");      // Returns: "/debug"
const result2 = parseSlashCommand("/hax");        // Returns: null
const result3 = parseSlashCommand("hello");       // Returns: null
```

### `slashRouter(req, res, next)`

Express-style middleware that attaches `req.slashCommand` property.

**Parameters:**
- `req` - Express request object (expects `req.body.content`)
- `res` - Express response object (unused)
- `next` - Express next function

**Behavior:**
- Sets `req.slashCommand` to the command if valid
- Sets `req.slashCommand` to `null` if invalid
- Always calls `next()` to continue middleware chain
- Handles missing `body` or `content` gracefully
- Automatically trims whitespace from content

**Example:**
```javascript
import express from 'express';
import { slashRouter } from "./src/middleware/slashRouter.js";

const app = express();
app.use(express.json());
app.use(slashRouter);

app.post('/messages', (req, res) => {
  if (req.slashCommand) {
    console.log(`Approved command: ${req.slashCommand}`);
    // Process slash command...
  } else if (req.body.content?.startsWith('/')) {
    console.log('Rejected unknown slash command');
    return res.status(400).json({ error: 'Unknown slash command' });
  } else {
    console.log('Regular message');
    // Process regular message...
  }
});
```

## Practical Usage

### Orchestrator Integration

```javascript
import { parseSlashCommand } from "./src/middleware/slashRouter.js";

function handleIncomingMessage(content) {
  const trimmed = content.trim();
  
  if (trimmed.startsWith('/')) {
    const approvedCommand = parseSlashCommand(trimmed);
    
    if (approvedCommand) {
      // Process approved slash command
      return processSlashCommand(approvedCommand);
    } else {
      // Reject unknown slash command
      throw new Error(`Unknown slash command: ${trimmed}`);
    }
  } else {
    // Handle regular message
    return processRegularMessage(content);
  }
}
```

### Security Features

- **Whitelist-only approach** - Only explicitly approved commands pass
- **Case-sensitive matching** - `/debug` ≠ `/DEBUG`
- **Exact string matching** - No partial matches or wildcards
- **Graceful error handling** - Returns `null` instead of throwing
- **No external dependencies** - Pure JavaScript implementation

## Testing

Run tests with:
```bash
npm test __tests__/slashRouter.test.js
```

Test coverage includes:
- ✅ All whitelisted commands accepted
- ✅ Unknown commands rejected
- ✅ Non-slash content rejected  
- ✅ Case sensitivity enforced
- ✅ Express middleware functionality
- ✅ Whitespace trimming
- ✅ Missing data handling

## Maintenance

To add new approved commands:

1. Update the `WHITELIST` Set in `src/middleware/slashRouter.js`
2. Add corresponding test cases in `__tests__/slashRouter.test.js`
3. Update this documentation
4. Ensure alignment with `system_prompt_architecture.md` Section 7

## Security Note

This middleware provides **runtime protection** against injection of unauthorized slash commands. All commands that reach the orchestrator's processing logic have been pre-approved through this whitelist system.

**Always validate slash commands** before processing them in your orchestrator to maintain security posture.