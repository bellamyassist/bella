# main.py
import os
import json
import logging
from pathlib import Path
from fastapi import FastAPI, Request, Body, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import secrets
import datetime
import psutil

# local imports (must be in same folder)
from chat_bella import chat_with_llm, load_config
from offload import create_job, has_cuda, run_local_job, push_jobs_to_remote, pull_results_from_remote

BASE = Path("C:/bella")
BASE.mkdir(parents=True, exist_ok=True)
OUTBOX = BASE / "outbox"
JOBS_DIR = BASE / "jobs"
RESULTS_DIR = BASE / "results"
TOKEN_FILE = BASE / "token.txt"
for p in (OUTBOX, JOBS_DIR, RESULTS_DIR):
    p.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    filename=str(OUTBOX / "server.log"),
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Create or load token
if not TOKEN_FILE.exists():
    tok = secrets.token_urlsafe(28)
    TOKEN_FILE.write_text(tok, encoding="utf-8")
else:
    tok = TOKEN_FILE.read_text(encoding="utf-8").strip()

logging.info("Loaded API token from %s", TOKEN_FILE)

app = FastAPI(title="Bella Backend")

# ----------------------
# CORS - allow local UI
# ----------------------
origins = [
    "http://127.0.0.1:5500",
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:5500"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ----------------------
# Utility: check token
# ----------------------
def check_token(req: Request):
    # token can be passed as header x-api-token or query param token
    header = req.headers.get("x-api-token") or req.headers.get("authorization")
    q = req.query_params.get("token")
    tok_sent = header or q
    if not tok_sent:
        return False
    # if "Bearer ..." split
    if tok_sent and tok_sent.lower().startswith("bearer "):
        tok_sent = tok_sent.split(" ", 1)[1]
    return tok_sent == tok

# ----------------------
# Basic endpoints
# ----------------------
@app.get("/health")
async def health():
    return {"status": "ok", "server": "bella", "time": datetime.datetime.utcnow().timestamp()}

@app.get("/api/token")
async def api_token(request: Request):
    # serve token only to allowed origins (UI)
    origin = request.headers.get("origin")
    # basic check - we accept local UI as origin - otherwise still return but client should be local
    logging.info("Serving token to local UI (origin=%s client=%s)", origin, request.client.host)
    return {"token": tok}

@app.get("/api/system")
async def api_system(request: Request):
    # returns CPU, memory, disk usage and running processes
    cpu = psutil.cpu_percent(interval=0.2)
    mem = psutil.virtual_memory().percent
    swap = psutil.swap_memory().percent
    disk = psutil.disk_usage(str(BASE)).percent
    return {
        "cpu_percent": cpu,
        "memory_percent": mem,
        "swap_percent": swap,
        "disk_percent": disk,
        "timestamp": datetime.datetime.utcnow().timestamp()
    }

# ----------------------
# Chat endpoint
# ----------------------
@app.post("/api/chat")
async def api_chat(request: Request, payload: dict = Body(...)):
    """
    payload: { "message": "hello", "model": "ollama" or "openai" }
    """
    # token check (optional, UI should call /api/token)
    if not check_token(request):
        logging.warning("Unauthorized attempt with token: None")
        raise HTTPException(status_code=401, detail="Unauthorized")

    message = payload.get("message", "")
    model = payload.get("model", None)
    if not message:
        raise HTTPException(status_code=400, detail="message required")
    logging.info("Chat message received")
    try:
        reply = chat_with_llm(message, model=model)
        return {"reply": reply}
    except Exception as e:
        logging.exception("Chat error")
        return JSONResponse(status_code=500, content={"error": str(e)})

# ----------------------
# Offload endpoints
# ----------------------
@app.post("/api/offload")
async def api_offload(request: Request, payload: dict = Body(...)):
    """
    Example payload:
    {
      "type":"backtest",
      "script":"C:/bella/neuro/backtest_runner.py",
      "args": {"strategy":"v1"},
      "resources": {"gpu": true}
    }
    """
    if not check_token(request):
        raise HTTPException(status_code=401, detail="Unauthorized")
    jobfile = create_job(payload)
    wants_gpu = payload.get("resources", {}).get("gpu", False)
    # run local if we have CUDA and job requests GPU
    if wants_gpu and has_cuda():
        logging.info("Running job locally (GPU available) %s", jobfile)
        # run in background thread
        import threading
        t = threading.Thread(target=run_local_job, args=(jobfile,))
        t.daemon = True
        t.start()
        return {"status": "running_local", "jobfile": jobfile}
    else:
        # push to remote via rclone for workers to pick up
        try:
            push_jobs_to_remote()
            logging.info("Job queued remote: %s", jobfile)
            return {"status": "queued_remote", "jobfile": jobfile}
        except Exception as e:
            logging.exception("Failed pushing jobs to remote")
            return {"status": "queued_local", "jobfile": jobfile, "error": str(e)}

@app.post("/api/offload/pull-results")
async def api_offload_pull(request: Request):
    if not check_token(request):
        raise HTTPException(status_code=401, detail="Unauthorized")
    try:
        pull_results_from_remote()
        return {"status": "pulled"}
    except Exception as e:
        logging.exception("pull error")
        raise HTTPException(status_code=500, detail=str(e))

# ----------------------
# Static listing endpoints for UI (scripts / jobs / results)
# ----------------------
@app.get("/api/scripts")
async def list_scripts(request: Request):
    if not check_token(request):
        raise HTTPException(status_code=401, detail="Unauthorized")
    # pick scripts from neuro folder or top-level 'scripts'
    scripts = []
    sdir = BASE / "neuro"
    if sdir.exists():
        for f in sdir.iterdir():
            if f.suffix in {".py", ".ps1", ".bat"}:
                scripts.append(f.name)
    return {"scripts": scripts}

@app.get("/api/jobs")
async def list_jobs(request: Request):
    if not check_token(request):
        raise HTTPException(status_code=401, detail="Unauthorized")
    files = sorted([p.name for p in JOBS_DIR.glob("*.json")])
    return {"jobs": files}

@app.get("/api/results")
async def list_results(request: Request):
    if not check_token(request):
        raise HTTPException(status_code=401, detail="Unauthorized")
    dirs = [d.name for d in RESULTS_DIR.iterdir() if d.is_dir()]
    return {"results": dirs}

# ----------------------
# Boot main
# ----------------------
if __name__ == "__main__":
    logging.info("Starting Bella backend (token source: %s)", TOKEN_FILE)
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
