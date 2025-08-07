import { buildPrompt } from "../src/utils/promptBuilder.js";
import { GLOBAL_PROMPT } from "../src/prompts/globalPrompt.js";

describe("promptBuilder", () => {
  it("creates minimal envelope", () => {
    const env = buildPrompt({
      l1Persona: "<<MODULE:CHAT>> persona",
      userInput: "Hi"
    });
    
    expect(env.messages[0].content).toBe(GLOBAL_PROMPT);
    expect(env.metadata.prompt_version).toBe("1.1");
    expect(env.metadata.require_json).toBe(false);
  });

  it("truncates memory to 20", () => {
    const mem = Array.from({ length: 30 }, (_, i) => `m${i}`);
    const env = buildPrompt({ l1Persona: "p", userInput: "x", memory: mem });
    const assistants = env.messages.filter(m => m.role === "assistant");
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
    const ephemeral = env.messages.find(m => m.name === "ephemeral");
    expect(ephemeral).toBeDefined();
    expect(ephemeral.content).toBe("/mode=json");
  });

  it("sets require_json flag correctly", () => {
    const env = buildPrompt({
      l1Persona: "test",
      userInput: "test",
      requireJson: true
    });
    expect(env.metadata.require_json).toBe(true);
  });

  it("throws error in development if envelope exceeds 64KB", () => {
    const originalEnv = process.env.NODE_ENV;
    delete process.env.NODE_ENV; // Ensure it's not "production"
    
    // Create a scenario that will exceed 64KB after truncation
    // Using large memory array + large persona + large user input
    const largePersona = "x".repeat(16000); // Close to 16KB limit
    const largeInput = "y".repeat(16000);   // Close to 16KB limit  
    const largeMemory = Array.from({ length: 20 }, (_, i) => "z".repeat(15000)); // 20 x 15KB strings
    
    expect(() => {
      buildPrompt({
        l1Persona: largePersona,
        userInput: largeInput,
        memory: largeMemory
      });
    }).toThrow(/Prompt envelope .* bytes > 64 kB spec limit/);
    
    process.env.NODE_ENV = originalEnv;
  });

  it("does not throw error in production even with large envelope", () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "production";
    
    const largeInput = "x".repeat(70000);
    
    expect(() => {
      buildPrompt({
        l1Persona: "test",
        userInput: largeInput
      });
    }).not.toThrow();
    
    process.env.NODE_ENV = originalEnv;
  });
});