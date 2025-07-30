import asyncio
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List

import pytz
from dateutil.rrule import rrulestr, rrule
from jsonschema import validate, ValidationError

# --- Output JSON Schema ---
SCHEDULE_SCHEMA = {
    "type": "object",
    "properties": {
        "events": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "session_id": {"type": "string", "format": "uuid"},
                    "task_id": {"type": "string"},
                    "start_time": {"type": "string", "format": "date-time"},
                    "end_time": {"type": "string", "format": "date-time"},
                    "status": {"type": "string", "enum": ["scheduled", "conflict"]},
                },
                "required": ["session_id", "task_id", "start_time", "end_time", "status"],
            },
        },
        "conflicts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "task_id": {"type": "string"},
                    "conflict_with": {"type": "string", "format": "uuid"},
                    "reason": {"type": "string"},
                },
                "required": ["task_id", "conflict_with", "reason"],
            },
        },
        "exceptions": {"type": "array"},
    },
    "required": ["events", "conflicts", "exceptions"],
}


def _check_overlap(start1: datetime, end1: datetime, start2: datetime, end2: datetime) -> bool:
    """Checks if two datetime ranges overlap."""
    return (start1 < end2) and (end1 > start2)


async def schedule(task_list: dict) -> dict:
    """
    Expands task recurrence rules into concrete calendar events for the next 30 days,
    detecting any scheduling conflicts.

    Args:
        task_list: A dictionary containing a list of tasks, matching the
                   output of the TaskDecomposerAgent.

    Returns:
        A dictionary containing a list of scheduled events, conflicts, and exceptions.

    Raises:
        ValueError: If the final generated payload fails schema validation.
    """
    # --- Setup ---
    all_events: List[Dict[str, Any]] = []
    conflicts: List[Dict[str, Any]] = []
    tz = pytz.timezone("America/Mexico_City")
    today = datetime.now(tz).replace(hour=0, minute=0, second=0, microsecond=0)
    until_date = today + timedelta(days=30)

    # --- 1. Expand RRULEs into concrete events ---
    for task in task_list.get("tasks", []):
        task_id = task.get("task_id")
        duration_minutes = task.get("estimated_minutes", 60)
        
        # Set default start time for recurrences
        dtstart = today.replace(hour=9, minute=0)

        try:
            rule = rrulestr(task["recurrence_rule"], dtstart=dtstart)
            occurrences = rule.between(today, until_date, inc=True)

            for start_time in occurrences:
                end_time = start_time + timedelta(minutes=duration_minutes)
                all_events.append({
                    "session_id": str(uuid.uuid4()),
                    "task_id": task_id,
                    "start_time": start_time,
                    "end_time": end_time,
                    "status": "scheduled", # Tentative status
                })
        except (ValueError, KeyError) as e:
            print(f"Warning: Could not parse rrule for task {task_id}: {e}")
            continue

    # --- 2. Detect Conflicts ---
    # A simple O(n^2) check is sufficient for a small number of events.
    for i in range(len(all_events)):
        for j in range(i + 1, len(all_events)):
            event1 = all_events[i]
            event2 = all_events[j]

            if _check_overlap(event1["start_time"], event1["end_time"], event2["start_time"], event2["end_time"]):
                # Mark both events as having a conflict
                event1["status"] = "conflict"
                event2["status"] = "conflict"

                # Add conflict entries for both tasks
                conflicts.append({
                    "task_id": event1["task_id"],
                    "conflict_with": event2["session_id"],
                    "reason": "overlap",
                })
                conflicts.append({
                    "task_id": event2["task_id"],
                    "conflict_with": event1["session_id"],
                    "reason": "overlap",
                })

    # --- 3. Finalize and Validate ---
    # Convert datetimes to ISO 8601 strings for the final payload
    for event in all_events:
        event["start_time"] = event["start_time"].isoformat()
        event["end_time"] = event["end_time"].isoformat()

    result = {
        "events": all_events,
        "conflicts": conflicts,
        "exceptions": [],
    }

    try:
        validate(instance=result, schema=SCHEDULE_SCHEMA)
        return result
    except ValidationError as e:
        raise ValueError(f"Invalid JSON schema for schedule: {e.message}")


# --- Example Usage (for testing) ---
async def main():
    test_tasks = {
        "tasks": [
            {
                "task_id": "task_001",
                "description": "Morning run",
                "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR",
                "estimated_minutes": 30,
                "dependencies": [],
            },
            {
                "task_id": "task_002",
                "description": "Team meeting",
                "recurrence_rule": "RRULE:FREQ=WEEKLY;BYDAY=MO", # Conflicts with run
                "estimated_minutes": 60,
                "dependencies": [],
            },
        ]
    }
    try:
        schedule_result = await schedule(test_tasks)
        import json
        print(json.dumps(schedule_result, indent=2))
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
