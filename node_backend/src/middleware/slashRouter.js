const WHITELIST = new Set(["/mode=json", "/debug", "/summarize", "/sql", "/rephrase"]);

/**
 * Validate an incoming slash-command. Returns the original string if allowed,
 * otherwise returns `null` so callers can reject or ignore.
 * @param {string} text raw message content (should start with '/')
 */
export function parseSlashCommand(text) {
  return WHITELIST.has(text) ? text : null;
}

/**
 * Express-style middleware (optional use): attaches `req.slashCommand` if valid.
 */
export function slashRouter(req, _res, next) {
  const message = req.body?.content?.trim();
  req.slashCommand = WHITELIST.has(message) ? message : null;
  next();
}