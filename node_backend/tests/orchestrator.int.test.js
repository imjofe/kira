import {jest} from '@jest/globals';
import request from 'supertest';

const axios = {
  post: jest.fn()
};

jest.unstable_mockModule('axios', () => ({
  default: axios
}));

let server;

beforeAll(async () => {
  process.env.PORT = '0';
  const module = await import('../src/server.js');
  server = module.default;
});

const describe_if = (condition) => (condition ? describe.skip : describe);

describe_if(process.env.INTEGRATION_OFF === 'true')('Orchestrator Integration Test', () => {
  beforeEach(() => {
    axios.post.mockClear();
  });

  test('should orchestrate the full new_goal flow', async () => {
    // --- Mocked Agent Responses ---
    const mockIntentResponse = {
      status: 'success',
      agent_name: 'IntentClassifierAgent',
      output_data: { intent: 'new_goal' },
    };

    const mockGoalResponse = {
      type: 'skill',
      description: 'Learn Spanish',
      deadline: null,
      constraints: { days_available: [], time_windows: [] },
      preferences: {},
    };

    const mockTaskResponse = {
      tasks: [
        {
          task_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
          goal_id: 'g1h2i3j4-k5l6-7890-1234-567890abcdef',
          description: 'Practice Spanish vocabulary for 15 minutes',
          recurrence_rule: 'RRULE:FREQ=DAILY',
          estimated_minutes: 15,
          dependencies: [],
        },
      ],
    };

    const mockScheduleResponse = {
      events: [],
      conflicts: [],
      exceptions: [],
    };

    axios.post
      .mockResolvedValueOnce({ data: mockIntentResponse })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'GoalParserAgent', output_data: mockGoalResponse } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'TaskDecomposerAgent', output_data: mockTaskResponse } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'SchedulerAgent', output_data: mockScheduleResponse } });

    // --- Supertest Request ---
    const response = await request(server)
      .post('/messages')
      .send({
        type: 'user_sends_message',
        data: { text: 'I want to learn Spanish' },
      });

    // --- Assertions ---
    expect(response.status).toBe(200);
    expect(response.body.data.tasks).toBeDefined();
    expect(response.body.data.tasks.length).toBeGreaterThan(0);
    expect(response.body.data.tasks[0].description).toEqual('Practice Spanish vocabulary for 15 minutes');
  });
});