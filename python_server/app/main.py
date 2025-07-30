
import os
import uvicorn
from datetime import datetime
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, Callable, Awaitable
from dotenv import load_dotenv

# --- Agent Imports ---
from app.agents.intent_classifier import classify as intent_classifier_agent
from app.agents.goal_parser import parse as goal_parser_agent
from app.agents.task_decomposer import decompose as task_decomposer_agent
from app.agents.scheduler import schedule as scheduler_agent
from app.agents.adaptation import adapt as adaptation_agent

# --- Environment Loading ---
load_dotenv()

# --- Configuration ---
PORT = os.environ.get("PORT", 8000)

# --- Logging ---
def log_info(message: str):
    """Simple structured INFO logger."""
    print(f"[{datetime.utcnow().isoformat()}] [python_inference] [INFO] {message}")

def log_error(message: str):
    """Simple structured ERROR logger."""
    print(f"[{datetime.utcnow().isoformat()}] [python_inference] [ERROR] {message}")

# --- Pydantic Schemas ---

class AgentRequest(BaseModel):
    agent_name: str = Field(..., description="The name of the agent to invoke.")
    input_data: Dict[str, Any] = Field(..., description="Agent-specific input data.")

class AgentError(BaseModel):
    code: str
    message: str

class AgentSuccessResponse(BaseModel):
    status: str = "success"
    agent_name: str
    output_data: Dict[str, Any]

class AgentErrorResponse(BaseModel):
    status: str = "error"
    agent_name: str
    error: AgentError

class HealthResponse(BaseModel):
    status: str = "ok"

# --- Agent Dispatch Table ---
AGENTS: Dict[str, Callable[..., Awaitable[Dict[str, Any]]]] = {
    "IntentClassifierAgent": intent_classifier_agent,
    "GoalParserAgent": goal_parser_agent,
    "TaskDecomposerAgent": task_decomposer_agent,
    "SchedulerAgent": scheduler_agent,
    "AdaptationAgent": adaptation_agent,
}

# --- FastAPI Application ---
app = FastAPI()

# --- Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# --- API Endpoints ---

@app.get("/health", response_model=HealthResponse, summary="Health Check")
async def health_check():
    """Returns a 200 OK status if the server is healthy."""
    return HealthResponse()

@app.post(
    "/invoke_agent",
    response_model=AgentSuccessResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {"model": AgentErrorResponse},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": AgentErrorResponse},
    },
    summary="Invoke a named agent",
)
async def invoke_agent(request: AgentRequest):
    """
    Invokes a specified agent with the given input data.
    """
    log_info(f"Received request for agent: {request.agent_name}")

    agent_func = AGENTS.get(request.agent_name)

    if not agent_func:
        error_message = f"Agent '{request.agent_name}' not found."
        log_error(error_message)
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content=AgentErrorResponse(
                agent_name=request.agent_name,
                error=AgentError(code="agent_not_found", message=error_message)
            ).dict(),
        )

    try:
        # --- Agent Logic ---
        if request.agent_name in ["TaskDecomposerAgent", "SchedulerAgent", "AdaptationAgent"]:
            output_data = await agent_func(request.input_data)
        else:
            user_text = request.input_data.get("text")
            if not user_text:
                raise ValueError(f"Missing 'text' field in input_data for {request.agent_name}")
            output_data = await agent_func(user_text)
            
        log_info(f"Successfully processed agent '{request.agent_name}'.")

        return AgentSuccessResponse(
            agent_name=request.agent_name,
            output_data=output_data
        )

    except ValueError as e:
        error_code = "bad_request"
        if request.agent_name == "TaskDecomposerAgent":
            error_code = "DecomposeFailure"
        elif request.agent_name == "SchedulerAgent":
            error_code = "ScheduleFailure"
        elif request.agent_name == "AdaptationAgent":
            error_code = "AdaptationFailure"
        
        error_message = f"Bad Request: {str(e)}"
        log_error(error_message)
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content=AgentErrorResponse(
                agent_name=request.agent_name,
                error=AgentError(code=error_code, message=str(e))
            ).dict(),
        )
    except Exception as e:
        error_message = f"Internal Server Error while processing agent '{request.agent_name}': {str(e)}"
        log_error(error_message)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=AgentErrorResponse(
                agent_name=request.agent_name,
                error=AgentError(code="internal_server_error", message="An unexpected error occurred.")
            ).dict(),
        )

# --- Server Entrypoint ---
if __name__ == "__main__":
    log_info(f"Starting server on http://0.0.0.0:{PORT}")
    uvicorn.run("app.main:app", host="0.0.0.0", port=int(PORT), reload=True)
