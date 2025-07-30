import { v4 as uuidv4 } from 'uuid';
import dayjs from 'dayjs';

// In-memory cache for the schedule
let scheduleCache = {
  events: [],
  conflicts: [],
  exceptions: [],
};

export default function (app, wss, axios, Ajv, schemasByAgent) {
  const log = (level, trace_id, msg) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${trace_id}] [events_route] [${level.toUpperCase()}] ${msg}`);
  };

  app.use('/events', (req, res, next) => {
    req.trace_id = req.headers['x-trace-id'] || uuidv4();
    res.setHeader('X-Trace-Id', req.trace_id);
    log('INFO', req.trace_id, `${req.method} ${req.url}`);
    next();
  });

  app.patch('/events/:session_id', async (req, res) => {
    const { session_id } = req.params;
    const { status } = req.body;
    const traceId = req.trace_id;

    if (!['completed', 'skipped', 'rescheduled'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    try {
      const response = await axios.post(
        `${process.env.PYTHON_API_URL}/invoke_agent`,
        {
          agent_name: 'AdaptationAgent',
          input_data: {
            schedule: scheduleCache,
            adaptation_request: { action: status, session_id },
          },
        },
        {
          headers: { 'X-Trace-Id': traceId },
        }
      );

      scheduleCache = response.data.output_data;

      wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(
            JSON.stringify({
              type: 'schedule_update',
              data: { session_id, status },
            })
          );
        }
      });

      res.json({ status: 'ok' });
    } catch (error) {
      log('ERROR', traceId, error.message);
      res.status(500).json({ error: 'Failed to update event' });
    }
  });

  app.get('/events/upcoming', (req, res) => {
    const traceId = req.trace_id;
    try {
      const now = dayjs();
      const upcomingEvents = scheduleCache.events
        .filter((event) => {
          const eventDate = dayjs(event.start_time);
          return eventDate.isAfter(now) && eventDate.isBefore(now.add(7, 'day'));
        })
        .sort((a, b) => dayjs(a.start_time).valueOf() - dayjs(b.start_time).valueOf());

      res.json(upcomingEvents);
    } catch (error) {
      log('ERROR', traceId, error.message);
      res.status(500).json({ error: 'Failed to get upcoming events' });
    }
  });
}
