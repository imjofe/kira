/**
 * Orchestrator - Message routing and processing hub
 * 
 * This orchestrator handles incoming messages and routes them through either:
 * 1. Slash command processing (for L3 ephemeral commands)
 * 2. Gemma inference via PromptBuilder (for chat/assistant responses)
 * 3. Python agent flow (for goal processing and task management)
 */

import { WebSocketServer } from "ws";
import { buildPrompt } from "./utils/promptBuilder.js";
import { parseSlashCommand } from "./middleware/slashRouter.js";
import llamaBridge from "./llamaBridge.js";
import { randomUUID, randomBytes } from "crypto";

// Fallback UUID generation for older Node versions
const genId = () => (typeof randomUUID === "function" ? randomUUID() : randomBytes(16).toString("hex"));

/**
 * Enhanced orchestrator that routes messages through multiple processing paths
 */
export class MessageOrchestrator {
  constructor(options = {}) {
    this.port = options.port || 8787;
    this.wss = null;
    this.connectedClients = new Set();
    
    // Memory storage for conversation context (in production, this would be persistent)
    this.conversationMemory = new Map(); // clientId -> messages[]
  }

  /**
   * Start the WebSocket server and begin listening for connections
   */
  start() {
    this.wss = new WebSocketServer({ port: this.port });
    
    this.wss.on("connection", (ws) => {
      const clientId = genId();
      this.connectedClients.add(ws);
      
      // Initialize conversation memory for this client
      this.conversationMemory.set(clientId, []);
      
      console.log(`[${new Date().toISOString()}] [${clientId}] [orchestrator] [INFO] Client connected`);
      
      // Send welcome message
      this._sendFrame(ws, "server.welcome", {
        message: "Hello! I'm Kira, your AI wellness assistant. How can I help you today?",
        trace_id: clientId
      });

      ws.on("message", async (raw) => {
        await this._handleIncomingMessage(ws, clientId, raw);
      });

      ws.on("close", () => {
        this.connectedClients.delete(ws);
        this.conversationMemory.delete(clientId);
        console.log(`[${new Date().toISOString()}] [${clientId}] [orchestrator] [INFO] Client disconnected`);
      });

      ws.on("error", (error) => {
        console.log(`[${new Date().toISOString()}] [${clientId}] [orchestrator] [ERROR] WebSocket error: ${error.message}`);
      });
    });

    console.log(`[${new Date().toISOString()}] [orchestrator] [INFO] Orchestrator ready on ws://localhost:${this.port}`);
  }

  /**
   * Stop the WebSocket server
   */
  stop() {
    if (this.wss) {
      this.wss.close();
      this.connectedClients.clear();
      this.conversationMemory.clear();
    }
  }

  /**
   * Handle incoming messages and route them appropriately
   * @private
   */
  async _handleIncomingMessage(ws, clientId, raw) {
    let frame;
    try {
      frame = JSON.parse(raw.toString());
    } catch (error) {
      console.log(`[${new Date().toISOString()}] [${clientId}] [orchestrator] [WARN] Malformed frame: ${error.message}`);
      return; // Drop malformed frames silently
    }

    if (frame.type !== "message.user") {
      console.log(`[${new Date().toISOString()}] [${clientId}] [orchestrator] [WARN] Unexpected frame type: ${frame.type}`);
      return;
    }

    const content = frame.payload?.content?.trim() ?? "";
    const traceId = genId();
    
    console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [INFO] Processing message: "${content}"`);

    try {
      // Route 1: Slash command processing
      const slashCommand = parseSlashCommand(content);
      if (slashCommand) {
        await this._handleSlashCommand(ws, clientId, traceId, slashCommand);
        return;
      }

      // Route 2: Check if this looks like goal/task management content
      if (this._isGoalManagementIntent(content)) {
        console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [INFO] Routing to Python agents for goal processing`);
        this._sendFrame(ws, "server.info", {
          message: "🎯 I detect you're talking about goals! Let me connect you to the goal management system...",
          trace_id: traceId
        });
        return;
      }

      // Route 3: Gemma inference via PromptBuilder
      await this._handleGemmaInference(ws, clientId, traceId, content);
      
    } catch (error) {
      console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [ERROR] Processing failed: ${error.message}`);
      this._sendFrame(ws, "error", {
        message: `Processing failed: ${error.message}`,
        trace_id: traceId
      });
    }
  }

  /**
   * Handle slash command processing
   * @private
   */
  async _handleSlashCommand(ws, clientId, traceId, command) {
    console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [INFO] Processing slash command: ${command}`);
    
    // For now, just acknowledge the command
    // In production, these would trigger specific behaviors
    const responses = {
      "/mode=json": "🔧 Switched to JSON-only response mode",
      "/debug": "🐛 Debug mode enabled - you'll see detailed processing info",
      "/summarize": "📋 Summarization mode activated",
      "/sql": "💾 SQL query mode ready",
      "/rephrase": "✏️ Rephrasing mode enabled"
    };

    const responseMessage = responses[command] || `✅ Command ${command} processed`;

    this._sendFrame(ws, "command.accepted", {
      command,
      message: responseMessage,
      trace_id: traceId,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Handle Gemma inference using PromptBuilder
   * @private
   */
  async _handleGemmaInference(ws, clientId, traceId, content) {
    // Get conversation memory for context
    const memory = this.conversationMemory.get(clientId) || [];
    const memoryStrings = memory.slice(-10).map(m => m.content); // Last 10 messages

    // Build the prompt envelope
    const envelope = buildPrompt({
      l1Persona: "<<MODULE:CHAT>> You are Kira, an encouraging wellness assistant. Be supportive, concise, and helpful.",
      userInput: content,
      memory: memoryStrings,
      requireJson: false
    });

    // Add trace_id to metadata
    envelope.metadata.trace_id = traceId;

    console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [INFO] Running Gemma inference`);

    try {
      // Send typing indicator
      this._sendFrame(ws, "server.typing", {
        is_typing: true,
        trace_id: traceId
      });

      let fullResponse = "";
      
      // Stream tokens from Gemma
      for await (const token of llamaBridge.run({ prompt: envelope })) {
        fullResponse += token;
        
        // Send each token as it arrives
        this._sendFrame(ws, "message.delta", {
          role: "assistant",
          content: token,
          trace_id: traceId
        });
      }

      // Send final complete message
      this._sendFrame(ws, "message.complete", {
        role: "assistant", 
        content: fullResponse,
        trace_id: traceId
      });

      // Update conversation memory
      memory.push(
        { role: "user", content, timestamp: new Date().toISOString() },
        { role: "assistant", content: fullResponse, timestamp: new Date().toISOString() }
      );
      this.conversationMemory.set(clientId, memory);

      console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [INFO] Gemma inference completed`);

    } catch (error) {
      console.log(`[${new Date().toISOString()}] [${traceId}] [orchestrator] [ERROR] Gemma inference failed: ${error.message}`);
      
      this._sendFrame(ws, "error", {
        message: "I'm having trouble processing your message right now. Please try again.",
        trace_id: traceId
      });
    } finally {
      // Turn off typing indicator
      this._sendFrame(ws, "server.typing", {
        is_typing: false,
        trace_id: traceId
      });
    }
  }

  /**
   * Check if content looks like goal management intent
   * @private
   */
  _isGoalManagementIntent(content) {
    const goalKeywords = [
      'goal', 'learn', 'achieve', 'accomplish', 'plan', 'schedule',
      'task', 'todo', 'remind', 'deadline', 'by when', 'finish'
    ];
    
    const lowerContent = content.toLowerCase();
    return goalKeywords.some(keyword => lowerContent.includes(keyword));
  }

  /**
   * Send a WebSocket frame to the client
   * @private
   */
  _sendFrame(ws, type, payload) {
    try {
      const frame = JSON.stringify({ type, payload });
      ws.send(frame);
    } catch (error) {
      console.log(`[${new Date().toISOString()}] [orchestrator] [ERROR] Failed to send frame: ${error.message}`);
    }
  }
}

// For standalone execution
if (import.meta.url === `file://${process.argv[1]}`) {
  const orchestrator = new MessageOrchestrator({ port: 8787 });
  orchestrator.start();
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n[orchestrator] [INFO] Shutting down gracefully...');
    orchestrator.stop();
    process.exit(0);
  });
}