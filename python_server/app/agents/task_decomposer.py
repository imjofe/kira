
import ollama
import re
import json
import asyncio
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List
from jsonschema import validate, ValidationError

# --- Output JSON Schema ---
TASK_LIST_SCHEMA = {
    "type": "object",
    "properties": {
        "tasks": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "task_id": {"type": "string", "format": "uuid"},
                    "goal_id": {"type": ["string", "null"], "format": "uuid"},
                    "description": {"type": "string"},
                    "recurrence_rule": {"type": "string"},
                    "estimated_minutes": {"type": "number"},
                    "dependencies": {"type": "array", "items": {"type": "string", "format": "uuid"}}
                },
                "required": ["task_id", "goal_id", "description", "recurrence_rule", "estimated_minutes", "dependencies"]
            }
        }
    },
    "required": ["tasks"]
}

# --- Few-shot examples for the prompt ---
FEW_SHOT_PROMPT = f"""\
You are an expert at decomposing a high-level goal into a list of concrete, recurring tasks. Based on the user's parsed goal (in JSON), generate a `tasks` array. Return ONLY the JSON object.

**Example 1: Fitness Goal**
*Input Goal JSON:*
```json
{{
  "type": "fitness",
  "description": "Run a 10k in 3 months",
  "deadline": "{(datetime.now() + timedelta(days=90)).strftime('%Y-%m-%d')}",
  "constraints": {{
    "days_available": ["Tuesday", "Thursday", "Saturday"],
    "time_windows": ["morning"]
  }},
  "preferences": {{}}
}}
```
*Output Tasks JSON:*
```json
{{
  "tasks": [
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Long run (increase distance by 10% each week)",
      "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=SA",
      "estimated_minutes": 60,
      "dependencies": []
    }},
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Interval training session",
      "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=TU",
      "estimated_minutes": 45,
      "dependencies": []
    }},
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Tempo run",
      "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=TH",
      "estimated_minutes": 45,
      "dependencies": []
    }}
  ]
}}
```

**Example 2: Skill Goal**
*Input Goal JSON:*
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
*Output Tasks JSON:*
```json
{{
  "tasks": [
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Complete one chapter of Python textbook",
      "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=SA",
      "estimated_minutes": 90,
      "dependencies": []
    }},
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Work on a small Python coding project",
      "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=SU",
      "estimated_minutes": 120,
      "dependencies": []
    }}
  ]
}}
```

**Example 3: Project Goal**
*Input Goal JSON:*
```json
{{
  "type": "project",
  "description": "Build a portfolio website",
  "deadline": "{datetime.now().year}-12-31",
  "constraints": {{}},
  "preferences": {{ "tone": "encouraging" }}
}}
```
*Output Tasks JSON:*
```json
{{
  "tasks": [
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Phase 1: Research and Design",
      "recurrence_rule": "RRULE:FREQ=ONCE",
      "estimated_minutes": 240,
      "dependencies": []
    }},
    {{
      "task_id": "{uuid.uuid4()}",
      "goal_id": null,
      "description": "Phase 2: Development",
      "recurrence_rule": "RRULE:FREQ=ONCE",
      "estimated_minutes": 600,
      "dependencies": ["<task_id_from_phase_1>"]
    }}
  ]
}}
```
"""

async def decompose(parsed_goal: Dict[str, Any]) -> Dict[str, List[Dict[str, Any]]]:
    """
    Decomposes a parsed goal into a list of tasks.
    """
    goal_id = parsed_goal.get("goal_id") # Or however the ID is passed

    try:
        # 1. Primary Path: Ollama
        prompt = f"""\
        {FEW_SHOT_PROMPT}

        Now, parse the following user goal. Respond with ONLY the JSON object containing the 'tasks' array.

        **User input:**
        ```json
        {json.dumps(parsed_goal, indent=2)}
        ```
        **JSON output:**
        """
        response = await ollama.chat(
            model='gemma:3n-instruct',
            messages=[{'role': 'user', 'content': prompt}],
            options=ollama.Options(temperature=0.1)
        )
        
        json_string = response['message']['content'].strip()
        json_start = json_string.find('{')
        json_end = json_string.rfind('}') + 1
        json_string = json_string[json_start:json_end]
        task_data = json.loads(json_string)

        # Add UUIDs to the tasks from the model
        for task in task_data.get("tasks", []):
            task["task_id"] = str(uuid.uuid4())
            task["goal_id"] = goal_id

    except Exception as e:
        print(f"[TaskDecomposer] Ollama call failed: {e}. Falling back to rule-based decomposer.")
        # 2. Fallback Path: Rules
        task_data = _fallback_decomposer(parsed_goal)

    # 3. Validation
    try:
        validate(instance=task_data, schema=TASK_LIST_SCHEMA)
        return task_data
    except ValidationError as e:
        raise ValueError(f"Invalid JSON schema for tasks: {e.message}")

def _fallback_decomposer(parsed_goal: Dict[str, Any]) -> Dict[str, List[Dict[str, Any]]]:
    """A simple rule-based fallback to create a basic task list."""
    days_map = {
        "monday": "MO", "tuesday": "TU", "wednesday": "WE", 
        "thursday": "TH", "friday": "FR", "saturday": "SA", "sunday": "SU"
    }
    
    days_available = parsed_goal.get("constraints", {}).get("days_available", [])
    byday = [days_map[day.lower()] for day in days_available if day.lower() in days_map]

    if not byday and parsed_goal.get("type") == "fitness":
        byday = ["MO", "WE", "FR"] # Default for fitness

    if not byday:
        # Default for any other type if no days are specified
        byday = ["MO"] 

    rrule = f"RRULE:FREQ=WEEKLY;BYDAY={','.join(byday)}"

    return {
        "tasks": [
            {
                "task_id": str(uuid.uuid4()),
                "goal_id": parsed_goal.get("goal_id"),
                "description": f"Work on your goal: {parsed_goal.get('description', '...')}",
                "recurrence_rule": rrule,
                "estimated_minutes": 60,
                "dependencies": []
            }
        ]
    }

# --- Example Usage (for testing) ---
async def main():
    test_goal = {
        "type": "skill",
        "description": "Learn to play the guitar",
        "deadline": "2025-12-31",
        "constraints": {
            "days_available": ["Tuesday", "Thursday"],
            "time_windows": ["evening"]
        },
        "preferences": {},
        "goal_id": str(uuid.uuid4())
    }
    try:
        tasks_result = await decompose(test_goal)
        print(json.dumps(tasks_result, indent=2))
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
