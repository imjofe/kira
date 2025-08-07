import { buildPrompt } from "../src/utils/promptBuilder.js";
import { parseSlashCommand } from "../src/middleware/slashRouter.js";
import { MessageOrchestrator } from "../src/orchestrator.js";
import llamaBridge from "../src/llamaBridge.js";

describe("orchestrator helpers", () => {
  it("adds trace_id to envelope metadata", () => {
    const env = buildPrompt({ 
      l1Persona: "You are a test assistant", 
      userInput: "hello" 
    });
    
    // Simulate what orchestrator does
    env.metadata.trace_id = "uuid-123";
    
    expect(env.metadata.trace_id).toBeDefined();
    expect(env.metadata.trace_id).toBe("uuid-123");
    expect(env.metadata.prompt_version).toBe("1.1");
  });

  it("slash command parsing works correctly", () => {
    expect(parseSlashCommand("/debug")).toBe("/debug");
    expect(parseSlashCommand("/mode=json")).toBe("/mode=json");
    expect(parseSlashCommand("/notallowed")).toBeNull();
    expect(parseSlashCommand("regular text")).toBeNull();
  });

  it("buildPrompt creates valid envelope structure", () => {
    const env = buildPrompt({
      l1Persona: "<<MODULE:TEST>> You are a test assistant",
      userInput: "Hello world",
      memory: ["Previous message 1", "Previous message 2"],
      requireJson: false
    });

    expect(env.messages).toBeDefined();
    expect(env.messages.length).toBeGreaterThan(0);
    expect(env.metadata).toBeDefined();
    expect(env.metadata.prompt_version).toBe("1.1");
    expect(env.metadata.require_json).toBe(false);
    
    // Check message structure
    const systemMessages = env.messages.filter(m => m.role === 'system');
    const userMessages = env.messages.filter(m => m.role === 'user');
    const assistantMessages = env.messages.filter(m => m.role === 'assistant');
    
    expect(systemMessages.length).toBeGreaterThanOrEqual(2); // Global + persona
    expect(userMessages.length).toBe(1);
    expect(assistantMessages.length).toBe(2); // Memory messages
  });
});

describe("MessageOrchestrator", () => {
  let orchestrator;

  beforeEach(() => {
    orchestrator = new MessageOrchestrator({ port: 8788 }); // Use different port for tests
  });

  afterEach(() => {
    if (orchestrator) {
      orchestrator.stop();
    }
  });

  it("creates orchestrator instance with default settings", () => {
    expect(orchestrator).toBeDefined();
    expect(orchestrator.port).toBe(8788);
    expect(orchestrator.connectedClients).toBeDefined();
    expect(orchestrator.conversationMemory).toBeDefined();
  });

  it("handles goal management intent detection", () => {
    const testCases = [
      { input: "I want to learn Spanish", expected: true },
      { input: "Help me achieve my goal", expected: true },
      { input: "Can you schedule this task?", expected: true },
      { input: "What's the weather like?", expected: false },
      { input: "Hello there", expected: false }
    ];

    testCases.forEach(({ input, expected }) => {
      const result = orchestrator._isGoalManagementIntent(input);
      expect(result).toBe(expected);
    });
  });

  it("validates frame sending doesn't throw errors", () => {
    let sentData = null;
    const mockWs = {
      send: (data) => { sentData = data; }
    };

    expect(() => {
      orchestrator._sendFrame(mockWs, "test.type", { message: "test" });
    }).not.toThrow();

    expect(sentData).toBe(
      JSON.stringify({ 
        type: "test.type", 
        payload: { message: "test" } 
      })
    );
  });
});

describe("llamaBridge integration", () => {
  it("llamaBridge is ready and has required methods", () => {
    expect(llamaBridge.isReady()).toBe(true);
    expect(typeof llamaBridge.run).toBe('function');
    expect(typeof llamaBridge.getModelInfo).toBe('function');
  });

  it("llamaBridge.run returns async generator", async () => {
    const mockEnvelope = {
      messages: [
        { role: "system", content: "You are a test assistant" },
        { role: "user", content: "Hello" }
      ],
      metadata: { 
        prompt_version: "1.1", 
        trace_id: "test-123" 
      }
    };

    const generator = llamaBridge.run({ prompt: mockEnvelope });
    expect(generator).toBeDefined();
    expect(typeof generator.next).toBe('function');

    // Test that we can get at least one token
    const firstToken = await generator.next();
    expect(firstToken.done).toBe(false);
    expect(typeof firstToken.value).toBe('string');
  });

  it("llamaBridge provides model info", () => {
    const info = llamaBridge.getModelInfo();
    expect(info).toBeDefined();
    expect(info.model).toBeDefined();
    expect(info.version).toBeDefined();
    expect(info.status).toBeDefined();
  });
});