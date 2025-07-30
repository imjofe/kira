import pytest
import os
import asyncio
import uuid
from datetime import datetime, timedelta

import pytz
from jsonschema import validate, ValidationError

# Assuming the agent code is in the path
from app.agents.scheduler import schedule, SCHEDULE_SCHEMA

# --- Test Configuration ---
SCHED_DISABLED = os.getenv("SCHED_DISABLED", "false").lower() == "true"

# --- Test Fixtures ---
@pytest.fixture
def sample_tasks():
    """Provides a sample task list with a deliberate conflict."""
    # Use a fixed start date to make the test deterministic
    tz = pytz.timezone("America/Mexico_City")
    today = datetime.now(tz).replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Find the next Monday to ensure the test is stable across the week
    start_of_week = today - timedelta(days=today.weekday())
    
    # RRULE that generates two events starting from the next Monday
    rrule_str = f"RRULE:FREQ=DAILY;COUNT=2"

    return {
        "tasks": [
            {
                "task_id": "task_A_daily_short",
                "description": "Task A: Daily stand-up",
                "recurrence_rule": rrule_str,
                "estimated_minutes": 60,
                "dependencies": [],
            },
            {
                "task_id": "task_B_daily_long",
                "description": "Task B: Deep work block",
                "recurrence_rule": rrule_str, # Same rule
                "estimated_minutes": 120, # Longer duration causes overlap
                "dependencies": [],
            },
        ]
    }

# --- Tests ---
@pytest.mark.xfail(SCHED_DISABLED, reason="Scheduler tests are disabled via environment variable.")
@pytest.mark.asyncio
async def test_schedule_generates_events_and_detects_conflicts(sample_tasks):
    """
    Tests that the scheduler correctly expands RRULEs and identifies overlaps.
    - GIVEN two tasks with the same daily recurrence for 2 days
    - WHEN one task's duration makes it overlap with the other
    - THEN the output should contain 4 total events and 4 conflict entries (2 pairs)
    """
    # 1. Run the scheduler agent
    result = await schedule(sample_tasks)

    # 2. Assert the basic structure of the response
    assert "events" in result
    assert "conflicts" in result
    assert "exceptions" in result

    # 3. Assert the expected number of events and conflicts
    # We expect 2 events for each of the 2 tasks = 4 total events
    assert len(result["events"]) == 4, "Should generate 4 events (2 for each task)"
    
    # The two tasks overlap on both days, creating 2 pairs of conflicts.
    # Each conflict pair generates 2 entries (one for each event involved).
    # So, we expect 2 * 2 = 4 conflict entries.
    assert len(result["conflicts"]) == 4, "Should detect 2 pairs of overlapping events"

    # 4. Validate the entire output against the schema
    try:
        validate(instance=result, schema=SCHEDULE_SCHEMA)
    except ValidationError as e:
        pytest.fail(f"Scheduler output failed schema validation: {e.message}")
