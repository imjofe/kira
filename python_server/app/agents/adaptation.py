import asyncio
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List

import pytz
from dateutil.parser import isoparse
from jsonschema import validate, ValidationError

# --- Schema (can be shared from scheduler) ---
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
                    "status": {"type": "string"},
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


def _recompute_conflicts(schedule: Dict[str, Any]) -> None:
    """
    Re-evaluates all events in the schedule and updates the conflicts list.
    This function modifies the schedule dict in-place.
    """
    events = schedule["events"]
    schedule["conflicts"] = [] # Reset conflicts

    # First, parse all ISO strings back to datetime objects for comparison
    for event in events:
        event["start_time_dt"] = isoparse(event["start_time"])
        event["end_time_dt"] = isoparse(event["end_time"])
        # Reset status to scheduled unless it's a terminal state
        if event["status"] not in ["skipped"]:
             event["status"] = "scheduled"


    for i in range(len(events)):
        for j in range(i + 1, len(events)):
            event1 = events[i]
            event2 = events[j]
            
            # Skipped events don't cause conflicts
            if event1["status"] == "skipped" or event2["status"] == "skipped":
                continue

            if _check_overlap(event1["start_time_dt"], event1["end_time_dt"], event2["start_time_dt"], event2["end_time_dt"]):
                event1["status"] = "conflict"
                event2["status"] = "conflict"
                schedule["conflicts"].append({"task_id": event1["task_id"], "conflict_with": event2["session_id"], "reason": "overlap"})
                schedule["conflicts"].append({"task_id": event2["task_id"], "conflict_with": event1["session_id"], "reason": "overlap"})

    # Clean up temporary datetime objects
    for event in events:
        del event["start_time_dt"]
        del event["end_time_dt"]


async def adapt(payload: dict) -> dict:
    """
    Adapts a given schedule based on a user's request to modify a session.

    Args:
        payload: A dictionary containing the current schedule and the adaptation request.

    Returns:
        The modified schedule with updated events, conflicts, and exceptions.

    Raises:
        ValueError: If the session_id is not found, the action is invalid,
                    or the final payload fails schema validation.
    """
    schedule = payload.get("schedule", {})
    request = payload.get("adaptation_request", {})
    
    session_id = request.get("session_id")
    action = request.get("action")

    target_event = next((e for e in schedule.get("events", []) if e["session_id"] == session_id), None)

    if not target_event:
        raise ValueError(f"Session with ID '{session_id}' not found in the schedule.")

    # --- Apply Adaptation Action ---
    exception_action = ""
    if action == "skip":
        target_event["status"] = "skipped"
        exception_action = "skipped"

    elif action in ["postpone", "reschedule"]:
        new_start_str = request.get("new_start_time")
        if not new_start_str:
            raise ValueError("Missing 'new_start_time' for reschedule/postpone action.")
        
        original_duration = isoparse(target_event["end_time"]) - isoparse(target_event["start_time"])
        new_start_time = isoparse(new_start_str)
        new_end_time = new_start_time + original_duration

        target_event["start_time"] = new_start_time.isoformat()
        target_event["end_time"] = new_end_time.isoformat()
        target_event["status"] = "rescheduled"
        exception_action = "rescheduled"

    elif action == "change_duration":
        new_minutes = request.get("new_estimated_minutes")
        if not isinstance(new_minutes, int) or new_minutes <= 0:
            raise ValueError("Invalid 'new_estimated_minutes' for change_duration action.")
            
        start_time = isoparse(target_event["start_time"])
        target_event["end_time"] = (start_time + timedelta(minutes=new_minutes)).isoformat()
        target_event["status"] = "updated"
        exception_action = "duration_changed"
        
    else:
        raise ValueError(f"Invalid adaptation action: '{action}'")

    # --- Record Exception and Recompute Conflicts ---
    if exception_action:
        schedule.setdefault("exceptions", []).append({
            "session_id": session_id,
            "action": exception_action,
            "timestamp": datetime.now(pytz.utc).isoformat(),
        })

    _recompute_conflicts(schedule)

    # --- Validate and Return ---
    try:
        validate(instance=schedule, schema=SCHEDULE_SCHEMA)
        return schedule
    except ValidationError as e:
        raise ValueError(f"Adapted schedule failed schema validation: {e.message}")

# --- Example Usage (for testing) ---
async def main():
    tz = pytz.timezone("America/Mexico_City")
    now = datetime.now(tz)
    
    sample_schedule = {
        "events": [
            {"session_id": "sess_001", "task_id": "task_A", "start_time": (now).isoformat(), "end_time": (now + timedelta(hours=1)).isoformat(), "status": "scheduled"},
            {"session_id": "sess_002", "task_id": "task_B", "start_time": (now + timedelta(minutes=30)).isoformat(), "end_time": (now + timedelta(hours=2)).isoformat(), "status": "scheduled"},
        ],
        "conflicts": [],
        "exceptions": [],
    }

    adaptation_req = {
        "action": "skip",
        "session_id": "sess_001",
    }
    
    payload = {"schedule": sample_schedule, "adaptation_request": adaptation_req}

    try:
        adapted_schedule = await adapt(payload)
        import json
        print(json.dumps(adapted_schedule, indent=2))
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
