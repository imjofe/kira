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

describe_if(process.env.EVENT_INT_OFF === 'true')('Events API Integration Test', () => {
  beforeEach(() => {
    axios.post.mockClear();
  });

  test('should create a schedule, update an event, and get upcoming events', async () => {
    // --- Mocked Agent Responses ---
    const mockScheduleResponse = {
      events: [
        {
          session_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
          task_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
          start_time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
          end_time: new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
          status: 'scheduled',
        },
      ],
      conflicts: [],
      exceptions: [],
    };

    const mockAdaptationResponse = {
      events: [
        {
          session_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
          task_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
          start_time: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          end_time: new Date(Date.now() + 25 * 60 * 60 * 1000).toISOString(),
          status: 'completed',
        },
      ],
      conflicts: [],
      exceptions: [],
    };

    axios.post
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'IntentClassifierAgent', output_data: { intent: 'new_goal' } } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'GoalParserAgent', output_data: { type: 'skill', description: 'Learn to cook', deadline: null, constraints: {}, preferences: {} } } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'TaskDecomposerAgent', output_data: { tasks: [{ task_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef', description: 'Buy groceries', recurrence_rule: 'RRULE:FREQ=DAILY;COUNT=1' }] } } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'SchedulerAgent', output_data: mockScheduleResponse } })
      .mockResolvedValueOnce({ data: { status: 'success', agent_name: 'AdaptationAgent', output_data: mockAdaptationResponse } });

    // 1. POST /messages to produce a schedule
    await request(server)
      .post('/messages')
      .send({
        type: 'user_sends_message',
        data: { text: 'I want to learn to cook' },
      });

    // 2. PATCH /events/sid-1 to update the status
    await request(server)
      .patch('/events/a1b2c3d4-e5f6-7890-1234-567890abcdef')
      .send({ status: 'completed' });

    // 3. GET /events/upcoming to assert the change
    const response = await request(server).get('/events/upcoming');

    expect(response.status).toBe(200);
    expect(response.body.length).toBeGreaterThan(0);
    expect(response.body[0].status).toBe('completed');
  });
});
