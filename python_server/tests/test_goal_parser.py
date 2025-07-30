

import pytest
import os
import asyncio
from jsonschema import validate, ValidationError
from app.agents.goal_parser import parse, GOAL_SCHEMA

# --- Test Configuration ---
OLLAMA_MISSING = os.getenv("OLLAMA_MISSING", "false").lower() == "true"

# --- Test Data ---
TEST_CASES = [
    # Fitness
    "I want to be able to do 20 pushups in a row in 2 months.",
    "My goal is to run a half-marathon by the end of the year.",
    "I will go to the gym on Monday, Wednesday, and Friday mornings.",

    # Skill
    "I want to learn how to play the ukulele.",
    "My objective is to become conversational in Spanish in one year.",
    "I will practice drawing for 30 minutes every day.",

    # Project
    "I need to build a new PC for gaming by Christmas.",
    "I'm going to write a short story this month.",
    "Plan and execute a small garden project in the backyard.",

    # Other / General
    "I want to be more mindful and meditate daily."
]

@pytest.mark.xfail(OLLAMA_MISSING, reason="Ollama is not available in this environment")
@pytest.mark.asyncio
async def test_goal_parser_structure_and_schema():
    """
    Tests that the goal parser returns a dictionary with the correct structure
    and that it validates against the defined JSON schema.
    """
    required_keys = {"type", "description", "deadline", "constraints", "preferences"}

    for text in TEST_CASES:
        # 1. Parse the goal
        parsed_goal = await parse(text)

        # 2. Check for required keys
        assert required_keys.issubset(parsed_goal.keys()), \
            f"Missing keys in parsed goal for input: '{text}'"

        # 3. Validate against the schema
        try:
            validate(instance=parsed_goal, schema=GOAL_SCHEMA)
        except ValidationError as e:
            pytest.fail(f"Schema validation failed for input: '{text}'\n{e.message}")


