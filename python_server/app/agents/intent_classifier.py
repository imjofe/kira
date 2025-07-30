"""
IntentClassifierAgent
Classifies raw user text into one of three intents:
  • new_goal            – the user expresses a goal they want to pursue
  • adaptation_request  – they ask to skip / postpone / change something
  • general_chat        – anything else

Primary path: LLM via Ollama (Gemma-3n).  Fallback: regex + keyword heuristics.
"""

import re
import asyncio
from typing import Dict

# --------- Few-shot prompt templates (for Gemma path) ----------
_FEWSHOT = [
    # new_goal
    ("I want to run a half-marathon next year.", "new_goal"),
    ("My goal is to learn Japanese in six months.", "new_goal"),
    ("I'd like to get better at playing guitar.", "new_goal"),
    # adaptation_request
    ("Can we skip today's workout? I'm sick.", "adaptation_request"),
    ("Let's postpone the study session to tomorrow.", "adaptation_request"),
    ("I need to reschedule my practice for next week.", "adaptation_request"),
    # general_chat
    ("What's the weather today?", "general_chat"),
    ("Tell me a joke.", "general_chat"),
    ("Thanks for your help!", "general_chat"),
]
_SYS_PROMPT = (
    "You are an intent-classification assistant. "
    "For each USER sentence, respond with one word only: "
    "'new_goal', 'adaptation_request', or 'general_chat'."
)

# ---------- Regex fallback -------------------------------------------------
_NEW_GOAL_PAT  = re.compile(
    r"""(?ix)
    ^\s*
    (i\s+want\s+to|i'd\s+like\s+to|my\s+goal\s+is|i\s+plan\s+to|
     i'm\s+going\s+to|i\s+need\s+to|i\s+will)
    """)
_ADAPT_PAT     = re.compile(r"(?i)\b(skip|postpone|reschedule|delay|move)\b")

async def _llm_intent(text: str) -> str:
    """Call Gemma via Ollama; return intent or raise RuntimeError."""
    import ollama  # local client
    shots = "\n".join([f"USER: {u}\nASSISTANT: {l}" for u, l in _FEWSHOT])
    prompt = f"{_SYS_PROMPT}\n\n{shots}\nUSER: {text}\nASSISTANT:"
    resp = await asyncio.to_thread(
        ollama.chat,
        model="gemma:3n",
        messages=[{"role": "user", "content": prompt}],
    )
    return resp["message"]["content"].strip().lower()

async def classify(text: str) -> Dict[str, str]:
    """
    Public entry-point – returns {"intent": "..."}.
    Falls back to regex heuristics if LLM fails or returns out-of-set label.
    """
    # 1️⃣  Try Gemma
    try:
        label = await _llm_intent(text)
        if label in {"new_goal", "adaptation_request", "general_chat"}:
            return {"intent": label}
    except Exception:
        pass  # swallow and try fallback

    # 2️⃣  Regex heuristic fallback
    if _NEW_GOAL_PAT.search(text):
        return {"intent": "new_goal"}
    if _ADAPT_PAT.search(text):
        return {"intent": "adaptation_request"}
    return {"intent": "general_chat"}