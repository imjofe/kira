This is the Node.js backend for Kira.

## Setup

```bash
npm install
npm run dev          # during coding
npm test             # run orchestrator tests
```

## Quick test

```bash
# REST
curl -X POST http://localhost:$PORT/messages \
     -H 'Content-Type: application/json' \
     -d '{"type":"user_sends_message","data":{"text":"ping"}}'

# WebSocket (using wscat)
wscat -c ws://localhost:$PORT/chat
```

## Quick Orchestrator Test

```bash
# 1. Start both services in separate terminals
PYTHONPATH=./app uvicorn app.main:app --reload --port 8000
npm run dev

# 2. WebSocket test (needs wscat)
wscat -c ws://localhost:3000/chat
# → type: {"type":"user_sends_message","data":{"text":"I want to learn guitar"}}

# 3. REST fallback
curl -X POST http://localhost:3000/messages \
     -H 'Content-Type: application/json' \
     -d '{"type":"user_sends_message","data":{"text":"I want to learn guitar"}}'
```
