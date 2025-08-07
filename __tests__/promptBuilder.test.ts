import { buildPrompt } from "../src/utils/promptBuilder.js";
import { GLOBAL_PROMPT } from "../src/prompts/globalPrompt.js";

describe("promptBuilder", () => {
  it("creates minimal envelope", () => {
    const env = buildPrompt({
      l1Persona: "<<MODULE:CHAT>> persona",
      userInput: "Hi"
    });
    
    expect((env.messages as any)[0].content).toBe(GLOBAL_PROMPT);
    expect((env.metadata as any).prompt_version).toBe("1.1");
    expect((env.metadata as any).require_json).toBe(false);
  });

  it("truncates memory to 20", () => {
    const mem = Array.from({ length: 30 }, (_, i) => `m${i}`);
    const env = buildPrompt({ l1Persona: "p", userInput: "x", memory: mem });
    const assistants = (env.messages as any[]).filter((m: any) => m.role === "assistant");
    expect(assistants.length).toBe(20);
    expect(assistants[0].content).toBe("m10");
    expect(assistants[19].content).toBe("m29");
  });

  it("includes ephemeral message when provided", () => {
    const env = buildPrompt({
      l1Persona: "test",
      userInput: "test",
      l3Ephemeral: "/mode=json"
    });
    const ephemeral = (env.messages as any[]).find((m: any) => m.name === "ephemeral");
    expect(ephemeral).toBeDefined();
    expect(ephemeral.content).toBe("/mode=json");
  });

  it("sets require_json flag correctly", () => {
    const env = buildPrompt({
      l1Persona: "test",
      userInput: "test",
      requireJson: true
    });
    expect((env.metadata as any).require_json).toBe(true);
  });

  it("throws error in development if envelope exceeds 64KB", () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "development";
    
    // Create a very large string that will exceed 64KB when serialized
    const largeInput = "x".repeat(70000);
    
    expect(() => {
      buildPrompt({
        l1Persona: "test",
        userInput: largeInput
      });
    }).toThrow(/Prompt envelope .* bytes > 64 kB spec limit/);
    
    process.env.NODE_ENV = originalEnv;
  });
});