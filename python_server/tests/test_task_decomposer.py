import pytest
import os
import asyncio
import uuid
from jsonschema import validate, ValidationError
from app.agents.task_decomposer import decompose, TASK_LIST_SCHEMA

# --- Test Configuration ---
OLLAMA_MISSING = os.getenv("OLLAMA_MISSING", "false").lower() == "true"

# --- Test Data ---
TEST_CASES = [
    {
        "type": "fitness",
        "description": "Run a marathon",
        "deadline": "2025-12-31",
        "constraints": {"days_available": ["Monday", "Wednesday", "Friday"], "time_windows": ["morning"]},
        "preferences": {},
        "goal_id": str(uuid.uuid4())
    },
    {
        "type": "skill",
        "description": "Learn to play the guitar",
        "deadline": None,
        "constraints": {"days_available": ["Saturday", "Sunday"], "time_windows": []},
        "preferences": {},
        "goal_id": str(uuid.uuid4())
    },
    {
        "type": "project",
        "description": "Build a web application",
        "deadline": "2025-10-01",
        "constraints": {},
        "preferences": {},
        "goal_id": str(uuid.uuid4())
    }
]

@pytest.mark.xfail(OLLAMA_MISSING, reason="Ollama is not available in this environment")
@pytest.mark.asyncio
async def test_task_decomposer_structure_and_schema():
    """
    Tests that the task decomposer returns a dictionary with the correct structure
    and that it validates against the defined JSON schema.
    """
    for parsed_goal in TEST_CASES:
        # 1. Decompose the goal
        task_list = await decompose(parsed_goal)

        # 2. Check for required keys and schema
        assert "tasks" in task_list, f"Missing 'tasks' key for goal: {parsed_goal['description']}"
        
        try:
            validate(instance=task_list, schema=TASK_LIST_SCHEMA)
        except ValidationError as e:
            pytest.fail(f"Schema validation failed for goal: {parsed_goal['description']}\n{e.message}")

