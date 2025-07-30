import ollama
import re
import json
import asyncio
from datetime import datetime, timedelta
from dateutil.parser import parse as parse_date
from dateutil.relativedelta import relativedelta
from jsonschema import validate, ValidationError
from typing import Dict, Any, List

# --- Output JSON Schema ---
GOAL_SCHEMA = {
    "type": "object",
    "properties": {
        "type": {"type": "string", "enum": ["fitness", "skill", "project", "other"]},
        "description": {"type": "string"},
        "deadline": {"type": ["string", "null"], "format": "date"},
        "constraints": {
            "type": "object",
            "properties": {
                "days_available": {"type": "array", "items": {"type": "string"}},
                "time_windows": {"type": "array", "items": {"type": "string"}}
            },
            "required": ["days_available", "time_windows"]
        },
        "preferences": {"type": "object"}
    },
    "required": ["type", "description", "deadline", "constraints", "preferences"]
}

# --- Few-shot examples for the prompt ---
FEW_SHOT_PROMPT = f"""\
You are an expert at parsing user goals into structured JSON. Convert the user's text into the following JSON format. The `deadline` must be an ISO date (YYYY-MM-DD) or null. The `type` must be one of: fitness, skill, project, other.

**Example 1:**
*User input:* "I want to run a 10k in 3 months. I can train on Mondays, Wednesdays, and Saturdays in the evenings."
*JSON output:*
```json
{{
  "type": "fitness",
  "description": "Run a 10k",
  "deadline": "{(datetime.now() + relativedelta(months=3)).strftime('%Y-%m-%d')}",
  "constraints": {{
    "days_available": ["Monday", "Wednesday", "Saturday"],
    "time_windows": ["evening"]
  }},
  "preferences": {{}}
}}
```

**Example 2:**
*User input:* "Help me learn Python. I have no deadline, just want to start. I can study on weekends."
*JSON output:*
```json
{{
  "type": "skill",
  "description": "Learn Python",
  "deadline": null,
  "constraints": {{
    "days_available": ["Saturday", "Sunday"],
    "time_windows": []
  }},
  "preferences": {{}}
}}
```

**Example 3:**
*User input:* "I need to build a portfolio website by the end of August. I want an encouraging tone from you."
*JSON output:*
```json
{{
  "type": "project",
  "description": "Build a portfolio website",
  "deadline": "{datetime.now().year}-08-31",
  "constraints": {{
    "days_available": [],
    "time_windows": []
  }},
  "preferences": {{
    "tone": "encouraging"
  }}
}}
```
"""

async def parse(text: str) -> Dict[str, Any]:
    """
    Parses a user's goal text into a structured JSON object.
    Uses Ollama first, then falls back to a regex-based parser.
    Validates the output against a JSON schema before returning.
    """
    try:
        # 1. Primary Path: Ollama
        prompt = f"""\
        {FEW_SHOT_PROMPT}

        Now, parse the following user input. Respond with ONLY the JSON object.

        **User input:** "{text}"
        **JSON output:**
        """
        response = await ollama.chat(
            model='gemma:3n-instruct',
            messages=[{'role': 'user', 'content': prompt}],
            options=ollama.Options(temperature=0.0)
        )
        
        # Clean and parse the model's response
        json_string = response['message']['content'].strip()
        json_start = json_string.find('{')
        json_end = json_string.rfind('}') + 1
        json_string = json_string[json_start:json_end]
        goal_data = json.loads(json_string)

    except Exception as e:
        print(f"[GoalParser] Ollama call failed: {e}. Falling back to rule-based parser.")
        # 2. Fallback Path: Regex
        goal_data = _fallback_parser(text)

    # 3. Validation
    try:
        validate(instance=goal_data, schema=GOAL_SCHEMA)
        return goal_data
    except ValidationError as e:
        raise ValueError(f"Invalid JSON schema after parsing: {e.message}")

def _fallback_parser(text: str) -> Dict[str, Any]:
    """A simple regex-based fallback to create a best-effort goal structure."""
    deadline = None
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    days_available = [day for day in days if re.search(r'\b' + day + r's?\b', text, re.IGNORECASE)]

    # Date parsing
    match = re.search(r'in (\d+) (weeks?|months?|days?)', text, re.IGNORECASE)
    if match:
        num, unit = match.groups()
        delta_args = {unit.rstrip('s') + 's': int(num)}
        deadline = (datetime.now() + relativedelta(**delta_args)).strftime('%Y-%m-%d')
    else:
        try:
            # Try parsing absolute dates like "by August 31st"
            parsed = parse_date(text, fuzzy=True)
            if parsed.year != datetime.now().year or parsed.month != datetime.now().month or parsed.day != datetime.now().day:
                deadline = parsed.strftime('%Y-%m-%d')
        except (ValueError, TypeError):
            pass # No deadline found

    return {
        "type": "other",
        "description": text, # Use raw text as description
        "deadline": deadline,
        "constraints": {
            "days_available": days_available,
            "time_windows": []
        },
        "preferences": {}
    }

# --- Example Usage (for testing) ---
async def main():
    test_cases = [
        "I want to run a 5k in 2 months, training on Tuesdays and Thursdays.",
        "I need to finish my website project by October 1st.",
        "Let's learn to play piano."
    ]
    for case in test_cases:
        try:
            result = await parse(case)
            print(f"Input: '{case}'\nParsed: {json.dumps(result, indent=2)}\n")
        except (ValueError, Exception) as e:
            print(f"Input: '{case}'\nError: {e}\n")

if __name__ == "__main__":
    asyncio.run(main())