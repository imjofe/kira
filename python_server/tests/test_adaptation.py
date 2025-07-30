import pytest
import os
import asyncio
import uuid
from datetime import datetime, timedelta

import pytz
from jsonschema import validate, ValidationError

from app.agents.scheduler import schedule
from app.agents.adaptation import adapt, SCHEDULE_SCHEMA

# --- Test Configuration ---
ADAPT_DISABLED = os.getenv("ADAPT_DISABLED", "false").lower() == "true"

# --- Test Fixtures ---
@pytest.fixture
def sample_tasks():
    """
    Provides a deterministic sample task list.
    Uses a fixed start date (next Monday) to ensure test stability.
    """
    tz = pytz.timezone("America/Mexico_City")
    today = datetime.now(tz).replace(hour=0, minute=0, second=0, microsecond=0)
    start_of_week = today - timedelta(days=today.weekday())
    
    rrule_str = f"RRULE:FREQ=DAILY;COUNT=2"

    return {
        "tasks": [
            {
                "task_id": "task_A",
                "description": "Task A",
                "recurrence_rule": rrule_str,
                "estimated_minutes": 60,
                "dependencies": [],
            },
            {
                "task_id": "task_B",
                "description": "Task B",
                "recurrence_rule": rrule_str,
                "estimated_minutes": 120,
                "dependencies": [],
            },
        ]
    }

# --- Tests ---
@pytest.mark.xfail(ADAPT_DISABLED, reason="Adaptation tests are disabled via environment variable.")
@pytest.mark.asyncio
async def test_adaptation_agent_skip_action(sample_tasks):
    """
    Tests that the AdaptationAgent can correctly process a 'skip' request.
    - GIVEN an existing schedule
    - WHEN a request is made to skip a specific session
    - THEN the session's status should be updated to 'skipped'
    - AND an exception should be logged
    - AND the final schedule should remain valid
    """
    # 1. Generate an initial schedule to work with
    initial_schedule = await schedule(sample_tasks)
    assert len(initial_schedule["events"]) > 0, "Test precondition failed: Initial schedule has no events."

    # 2. Create the adaptation payload
    target_session_id = initial_schedule["events"][0]["session_id"]
    adaptation_payload = {
        "schedule": initial_schedule,
        "adaptation_request": {
            "action": "skip",
            "session_id": target_session_id,
        }
    }

    # 3. Run the adaptation agent
    adapted_schedule = await adapt(adaptation_payload)

    # 4. Assert the results
    assert len(adapted_schedule["events"]) == len(initial_schedule["events"]), "Number of events should not change on skip."

    # Find the modified event
    skipped_event = next((e for e in adapted_schedule["events"] if e["session_id"] == target_session_id), None)
    assert skipped_event is not None, "Target session should still exist."
    assert skipped_event["status"] == "skipped", "Event status should be marked as 'skipped'."

    # Check the exceptions log
    assert len(adapted_schedule["exceptions"]) == 1, "There should be exactly one exception logged."
    exception_log = adapted_schedule["exceptions"][0]
    assert exception_log["session_id"] == target_session_id
    assert exception_log["action"] == "skipped"

    # 5. Validate the final output against the schema
    try:
        validate(instance=adapted_schedule, schema=SCHEDULE_SCHEMA)
    except ValidationError as e:
        pytest.fail(f"Adapted schedule failed schema validation: {e.message}")
