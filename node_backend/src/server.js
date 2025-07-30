import express from 'express';
import cors from 'cors';
import { WebSocketServer } from 'ws';
import http from 'http';
import axios from 'axios';
import Ajv from 'ajv';
import addFmts from 'ajv-formats';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';
import { schemasByAgent } from './schemas/agentSchemas.js';
import registerEventRoutes from './routes/events.js';

dotenv.config();

const PORT = process.env.PORT || 3000;
const PY_API = process.env.PYTHON_API_URL || 'http://localhost:8000';
const ajv = addFmts(new Ajv({ allErrors: true }));

const userSchedules = new Map();

const log = (level, trace_id, msg) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${trace_id}] [node_backend] [${level.toUpperCase()}] ${msg}`);
};

async function callAgent(agent, input, traceId, attempt = 1) {
    const schema = schemasByAgent[agent];
    if (!schema) {
        throw new Error(`No schema found for agent: ${agent}`);
    }

    log('INFO', traceId, `Calling agent: ${agent} (Attempt ${attempt})`);

    try {
        const response = await axios.post(
            `${PY_API}/invoke_agent`,
            {
                agent_name: agent,
                input_data: input,
            },
            {
                headers: { 'X-Trace-Id': traceId },
                timeout: 10000, // 10 seconds
            }
        );

        const dataToValidate = agent === 'IntentClassifierAgent' ? response.data : response.data.output_data;
        const validate = ajv.compile(schema);

        if (!validate(dataToValidate)) {
            const errorMsg = `Agent ${agent} response failed schema validation: ${ajv.errorsText(validate.errors)}`;
            log('ERROR', traceId, errorMsg);
            throw new Error(errorMsg);
        }

        log('INFO', traceId, `Agent ${agent} call successful.`);
        return response.data;

    } catch (error) {
        const isTimeout = error.code === 'ECONNABORTED';
        const is5xx = error.response && error.response.status >= 500;
        const isNetworkError = !error.response;

        log('ERROR', traceId, `Agent ${agent} call failed: ${error.message}`);

        if ((isTimeout || is5xx || isNetworkError) && attempt < 2) {
            const delay = 500 * attempt;
            log('INFO', traceId, `Retrying agent call in ${delay}ms...`);
            await new Promise(resolve => setTimeout(resolve, delay));
            return callAgent(agent, input, traceId, attempt + 1);
        }
        throw error;
    }
}

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
    req.trace_id = req.headers['x-trace-id'] || uuidv4();
    res.setHeader('X-Trace-Id', req.trace_id);
    log('INFO', req.trace_id, `${req.method} ${req.url}`);
    next();
});

app.get('/health', (req, res) => {
    log('INFO', req.trace_id, 'Health check requested');
    res.json({ status: 'ok' });
});

app.post('/messages', async (req, res) => {
    const traceId = req.trace_id;
    try {
        const inbound = req.body;
        if (inbound?.type !== 'user_sends_message') {
            return res.status(400).json({ error: 'Invalid message type' });
        }

        const intentRes = await callAgent('IntentClassifierAgent', { text: inbound.data.text }, traceId);
        const intent = intentRes.output_data.intent;

        if (intent === 'new_goal') {
            const pg = await callAgent('GoalParserAgent', { text: inbound.data.text }, traceId);
            const td = await callAgent('TaskDecomposerAgent', pg.output_data, traceId);
            const schedule = await callAgent('SchedulerAgent', td.output_data, traceId);
            userSchedules.set('demo_user', schedule.output_data.events);
            res.json({ type: 'server_sends_response', data: { text: '✅ Goal captured! Here are your tasks:', tasks: td.output_data.tasks } });
        } else {
            res.json({ type: 'server_sends_response', data: { text: `(stub) Intent ${intent} not yet supported.` } });
        }
    } catch (err) {
        log('ERROR', traceId, err.message);
        res.status(500).json({ type: 'error', data: { code: 'OrchestratorFailure', message: err.message } });
    }
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

registerEventRoutes(app, wss, axios, ajv, schemasByAgent);

wss.on('connection', (ws) => {
  const traceId = uuidv4();
  const log = (lvl,msg)=>console.log(`[${new Date().toISOString()}] [${traceId}] [node_backend] [${lvl.toUpperCase()}] ${msg}`);
  ws.send(JSON.stringify({type:'server_sends_response', trace_id: traceId, data:{text:' Hello! I\'m Kira. What\'s a goal you have in mind today?'}}));
  ws.on('message', async (buf) => {
    const inbound = JSON.parse(buf.toString());
    if(inbound?.type!=='user_sends_message'){ return; }
    ws.send(JSON.stringify({type:'server_typing_indicator', trace_id: traceId, data:{is_typing:true}}));
    try{
      const intentRes = await callAgent('IntentClassifierAgent',{text:inbound.data.text},traceId);
      const intent = intentRes.output_data.intent;
      if(intent==='new_goal'){
        const pg = await callAgent('GoalParserAgent',{text:inbound.data.text},traceId);
        const td = await callAgent('TaskDecomposerAgent', pg.output_data, traceId);
        const schedule = await callAgent('SchedulerAgent', td.output_data, traceId);
        userSchedules.set('demo_user', schedule.output_data.events);
        ws.send(JSON.stringify({type:'server_sends_response', trace_id: traceId, data:{text:'✅ Goal captured! Here are your tasks:',tasks:schedule.output_data.tasks}}));
      }else{
        ws.send(JSON.stringify({type:'server_sends_response', trace_id: traceId, data:{text:`(stub) Intent ${intent} not yet supported.`}}));
      }
    }catch(err){
      log('ERROR',traceId,err.message);
      ws.send(JSON.stringify({type:'error', trace_id: traceId, data:{code:'OrchestratorFailure',message:err.message}}));
    }
  });
});

if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    const trace_id = uuidv4();
    log('INFO', trace_id, `Server started on port ${PORT}`);
    log('INFO', trace_id, `Python API URL: ${PY_API}`);
  });
}

export default server;