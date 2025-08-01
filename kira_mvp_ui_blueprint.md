# Kira MVP – UI and Layer Interaction Blueprint  ✅ **CONFIRMED**

> **Revision 2025‑08‑01** – modules & flows locked; Contract A / B schemas finalized.

---

## 1. Modules / Screens (MVP Scope)

| Key | Screen / Module | Purpose | Typical User Actions |
|-----|-----------------|---------|----------------------|
| **SCHED** | **Schedule / Today** | Show today’s tasks in a timeline | Mark ✔ Done / ✖ Skip / ⏰ Snooze, **+ Quick Task** |
| **GOAL** | **Goals / Projects** | Plan long‑term goals (Kanban) | Drag cards, create / edit goal |
| **CAL**  | **Calendar** | Weekly calendar view | Tap day → see tasks/events |
| **CHAT** | **Chat** | Conversational interface to Gemma | Send prompt, receive reply, slash‑commands |
| **SET**  | **Settings** | Toggles & diagnostics | Dark mode, RAM debug, choose model, export data |
| *(overlay)* | **QuickAdd Sheet** | 15‑second task / note entry | Title, duration, save |

Modules & navigation confirmed – no further renames for MVP.

---

## 2. Layer Map per Module

```
┌────────┐  UI (Flutter)                            
│ Widget │  ──► NodeService (MethodChannel)         
│        │     └─► LlamaBridge (FFI)  (CHAT / QuickAdd)
└────────┘
                 ▼  WS JSON Frame = **Contract A**
        Node.js Orchestrator (TypeScript)
                 ▼  HTTP JSON = **Contract B**
        Python FastAPI + Agents (Gemma helpers)
                 ▼  lib
   Gemma 3n (llama.cpp)  •  SQLite DB
```

| Module | Direct Gemma (FFI) | Via Node (Contract A) | Via Python / SQLite (Contract B) |
|--------|-------------------|-----------------------|-----------------------------------|
| **SCHED**  | — | ✔ (task frames) | ✔ (`/tasks`) |
| **GOAL**   | — | ✔ (goal frames) | ✔ (`/goals`) |
| **CAL**    | — | — | ✔ (read‑only `/tasks`) |
| **CHAT**   | ✔ | — | ✔ (`/messages`) |
| **SET**    | — | — | ✔ (`/settings`) |
| **QuickAdd** | ✔ (optional summary) | ✔ | ✔ |

---

## 3. Action Flow Examples

### 3.1 Mark task **Done** (Schedule)
1. **Flutter** → `NodeService.send({"type":"task.update","payload":{"id":42,"status":"done"},"reqId":"abc123"})`
2. **Node** → validates (Contract A) → `PUT /tasks/42` to Python.
3. **Python** → update row → returns DTO; broadcasts
   `{"type":"task.update.ack","ok":true,"payload":{…},"reqId":"abc123"}`.
4. **Node** → forwards same frame to Flutter.
5. **Flutter** → provider updates UI.

### 3.2 Quick Task NLP Entry
1. **Flutter** → prompt to Gemma.
2. **Gemma** → `{title,start,duration}`.
3. **Flutter** → sends frame `task.create.suggested`.
4. **Node ↔ Python** → `/tasks` POST → broadcast `task.create.ack`.

### 3.3 Chat message
1. **Flutter** → `Gemma3n.run()`.
2. **Gemma** → reply.
3. **Flutter** → `POST /messages` (Contract B) to store.

---

## 4. Contract A – **WebSocket Frame Schema** (Flutter ↔ Node)

```jsonc
// envelope
{
  "type": "task.update",          // string, action identifier
  "payload": { … },                // object, schema per type
  "reqId": "uuid‑v4",            // optional correlation id
  "timestamp": "2025-08-01T16:20:00Z" // ISO‑8601, added by sender
}
```

### 4.1 Frame type catalogue (MVP)

| Type | Payload schema |
|------|----------------|
| `task.update` | `{ "id": int, "status": "done"\|"skip"\|"snooze" }` |
| `task.create.suggested` | `{ "title": string, "start": ISO8601, "duration": int /*min*/ }` |
| `goal.create` | `{ "title": string, "description": string, "deadline"?: ISO8601 }` |
| `goal.move` | `{ "id": int, "from": "Backlog"\|"Active"\|"Done", "to": same }` |
| `message.new` | `{ "role": "user"\|"assistant", "content": string }` |
| `settings.update` | `{ "key": string, "value": any }` |
| *(response)* `*.ack` | `{ "ok": bool, "error"?: string, "payload"?: object }` |

*All frames use UTF‑8 JSON; binary not required for MVP.*

---

## 5. Contract B – **REST + JSON** (Node ↔ Python)

| Endpoint | Verb | Req Body | Resp 200 |
|----------|------|----------|----------|
| `/tasks` | `GET` | — | `[TaskDto]` |
| `/tasks` | `POST` | `TaskCreate{title,start,duration,status}` | `TaskDto` |
| `/tasks/{id}` | `PUT` | `TaskPatch{status?,title?,start?,duration?}` | `TaskDto` |
| `/goals` | `GET` / `POST` / `PUT /{id}` | analogous to tasks | — |
| `/messages` | `GET?limit=` / `POST` | `MessageCreate{role,content}` | `[MessageDto]` |
| `/settings` | `GET` / `PUT` | JSON `{key,value}` | `{key,value}` |
| `/health` | `GET` | — | `{"status":"ok"}` |

### DTO skeletons

```jsonc
// TaskDto
{
  "id": 42,
  "title": "Weekly sync",
  "start": "2025-08-01T09:00:00-05:00",
  "end": "2025-08-01T09:30:00-05:00",
  "status": "done",          // pending | done | skip | snooze
  "created_at": "..."
}

// MessageDto
{
  "id": 101,
  "role": "assistant",
  "content": "Sure, here's the plan…",
  "ts": "2025-08-01T16:22:00Z"
}
```

*All endpoints return `HTTP 401` if Node forgets `X‑Auth‑Token` (future).* 

---

## 6. Next Steps (Updated)
1. **UI prompts** FL‑09→14 → generate widgets & providers.
2. Implement Python FastAPI endpoints (`/goals`,`/messages`,`/settings`).
3. Add Node frame router for each new `type`.
4. Extend SQLite schema: `goals`, `messages`, `settings` tables.
5. End‑to‑end tests for Schedule & Chat flows.

Blueprint frozen; any new actions must extend Contract A/B tables above.

