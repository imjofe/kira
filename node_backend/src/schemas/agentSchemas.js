export const intentSchema = {
  type: 'object',
  properties: {
    status: { const: 'success' },
    agent_name: { type: 'string' },
    output_data: {
      type: 'object',
      properties: {
        intent: { enum: ['new_goal', 'adaptation_request', 'general_chat'] },
      },
      required: ['intent'],
    },
  },
  required: ['status', 'output_data'],
};

export const parsedGoalSchema = {
  type: 'object',
  properties: {
    type: { type: 'string' },
    description: { type: 'string' },
    deadline: { type: ['string', 'null'], format: 'date' },
    constraints: { type: 'object' },
    preferences: { type: 'object' },
  },
  required: ['type', 'description', 'deadline', 'constraints', 'preferences'],
};

export const taskListSchema = {
  type: 'object',
  properties: {
    tasks: {
      type: 'array',
      minItems: 1,
      items: {
        type: 'object',
        properties: {
          task_id: { type: 'string', format: 'uuid' },
          description: { type: 'string' },
          recurrence_rule: { type: 'string' },
        },
        required: ['task_id', 'description', 'recurrence_rule'],
      },
    },
  },
  required: ['tasks'],
};

export const scheduleSchema = {
    type: 'object',
    properties: {
        events: {
            type: 'array',
            items: {
                type: 'object',
                properties: {
                    session_id: {type: 'string', format: 'uuid'},
                    task_id: {type: 'string'},
                    start_time: {type: 'string', format: 'date-time'},
                    end_time: {type: 'string', format: 'date-time'},
                    status: {type: 'string'},
                },
                required: ['session_id', 'task_id', 'start_time', 'end_time', 'status'],
            },
        },
        conflicts: {
            type: 'array',
            items: {
                type: 'object',
                properties: {
                    task_id: {type: 'string'},
                    conflict_with: {type: 'string', format: 'uuid'},
                    reason: {type: 'string'},
                },
                required: ['task_id', 'conflict_with', 'reason'],
            },
        },
        exceptions: {type: 'array'},
    },
    required: ['events', 'conflicts', 'exceptions'],
};

export const schemasByAgent = {
  IntentClassifierAgent: intentSchema,
  GoalParserAgent: parsedGoalSchema,
  TaskDecomposerAgent: taskListSchema,
  SchedulerAgent: scheduleSchema,
};