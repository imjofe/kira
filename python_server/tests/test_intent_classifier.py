
import pytest
import asyncio
from app.agents.intent_classifier import classify, INTENT_NEW_GOAL, INTENT_ADAPTATION_REQUEST, INTENT_GENERAL_CHAT

# --- Test Data ---
TEST_CASES = [
    # New Goal (6 cases)
    ("I want to learn how to code in Python.", INTENT_NEW_GOAL),
    ("My goal is to read 12 books this year.", INTENT_NEW_GOAL),
    ("I need to create a personal budget.", INTENT_NEW_GOAL),
    ("Let's start planning my vacation.", INTENT_NEW_GOAL),
    ("I aim to exercise three times a week.", INTENT_NEW_GOAL),
    ("I'm going to start a new side project.", INTENT_NEW_GOAL),
    ("I want to learn guitar", INTENT_NEW_GOAL),

    # Adaptation Request (6 cases)
    ("Can we change the deadline for my current task?", INTENT_ADAPTATION_REQUEST),
    ("I need to postpone my meeting until tomorrow.", INTENT_ADAPTATION_REQUEST),
    ("Let's skip today's workout session.", INTENT_ADAPTATION_REQUEST),
    ("I want to modify my savings goal.", INTENT_ADAPTATION_REQUEST),
    ("Reschedule my appointment to next Friday.", INTENT_ADAPTATION_REQUEST),
    ("I need to adjust my project's scope.", INTENT_ADAPTATION_REQUEST),

    # General Chat (8 cases)
    ("How are you doing today?", INTENT_GENERAL_CHAT),
    ("What is the weather like outside?", INTENT_GENERAL_CHAT),
    ("Tell me a fun fact.", INTENT_GENERAL_CHAT),
    ("Who created you?", INTENT_GENERAL_CHAT),
    ("That's interesting, thank you.", INTENT_GENERAL_CHAT),
    ("What time is it?", INTENT_GENERAL_CHAT),
    ("Can you help me with something?", INTENT_GENERAL_CHAT),
    ("Just saying hello.", INTENT_GENERAL_CHAT),
]

@pytest.mark.asyncio
async def test_intent_classifier_accuracy():
    """
    Tests the accuracy of the intent classifier against a predefined test suite.
    The test passes if the accuracy is >= 95%.
    """
    correct_predictions = 0
    total_cases = len(TEST_CASES)

    for text, expected_intent in TEST_CASES:
        result = await classify(text)
        if result.get("intent") == expected_intent:
            correct_predictions += 1

    accuracy = correct_predictions / total_cases
    print(f"Intent Classifier Accuracy: {accuracy:.2f} ({correct_predictions}/{total_cases})")

    assert accuracy >= 0.95, f"Accuracy ({accuracy:.2f}) is below the 95% threshold."

