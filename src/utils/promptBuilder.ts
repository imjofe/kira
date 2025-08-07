import { GLOBAL_PROMPT } from "../prompts/globalPrompt.js";

export interface BuildOptions {
  l1Persona: string;
  userInput: string;
  memory?: string[];
  l3Ephemeral?: string | null;
  requireJson?: boolean;
}

/**
 * Assemble the canonical prompt envelope.
 */
export function buildPrompt({
  l1Persona,
  userInput,
  memory = [],
  l3Ephemeral = null,
  requireJson = false
}: BuildOptions): Record<string, unknown> {
  const MEMORY_LIMIT = 20;
  const MAX_ENV_BYTES = 64 * 1024;
  const MAX_STR_BYTES = 16 * 1024;

  // 1. clip memory window
  const memWindow = memory.slice(-MEMORY_LIMIT);

  // 2. helper to truncate individual strings safely
  const truncate = (txt: string) =>
    Buffer.byteLength(txt, "utf8") <= MAX_STR_BYTES
      ? txt
      : Buffer.from(txt, "utf8").slice(0, MAX_STR_BYTES).toString();

  // 3. build messages array
  const messages: Array<Record<string, string>> = [
    { role: "system", content: GLOBAL_PROMPT },
    { role: "system", content: l1Persona },
    ...memWindow.map((m) => ({ role: "assistant", content: truncate(m) })),
    { role: "user", content: truncate(userInput) }
  ];
  if (l3Ephemeral) messages.push({ role: "system", content: l3Ephemeral, name: "ephemeral" });

  // 4. envelope
  const envelope = {
    messages,
    metadata: { prompt_version: "1.1", require_json: requireJson }
  };

  // 5. size guard (throws in dev, no-op in prod)
  if (process.env.NODE_ENV !== "production") {
    const bytes = Buffer.byteLength(JSON.stringify(envelope), "utf8");
    if (bytes > MAX_ENV_BYTES)
      throw new Error(`Prompt envelope ${bytes} bytes > 64 kB spec limit`);
  }

  return envelope;
}