# app.py - FastAPI application for Bella
import os
import time
import json
from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from .executor import Executor
from .safe_commands import map_command

ROOT = os.path.dirname(os.path.dirname(__file__))  # C:\bella\bella_core -> parent C:\bella
load_dotenv(dotenv_path=os.path.join(ROOT, ".env"))

app = FastAPI(title="Bella")

BELLA_API_KEY = os.getenv("BELLA_API_KEY", "").strip()

executor = Executor(root=ROOT)

def require_api_key(request: Request):
    # allow if local dev: request may come from UI and we auto-get the key on the client
    auth = request.headers.get("authorization", "")
    if not auth:
        raise HTTPException(status_code=403, detail="Forbidden: invalid API key")
    # header format: "Bearer <key>"
    parts = auth.split()
    if len(parts) != 2 or parts[0].lower() != "bearer" or parts[1] != BELLA_API_KEY:
        raise HTTPException(status_code=403, detail="Forbidden: invalid API key")
    return True

@app.get("/health")
def health():
    return {"status": "ok", "name": "Bella"}

@app.get("/__get_local_api_key")
def get_local_api_key():
    # Return masked key for local clients
    if not BELLA_API_KEY:
        raise HTTPException(status_code=404, detail="No local key configured")
    masked = BELLA_API_KEY[0] + ("*"*(len(BELLA_API_KEY)-2)) + BELLA_API_KEY[-1]
    return {"api_key": BELLA_API_KEY, "masked": masked}

@app.post("/debug_map")
async def debug_map(payload: dict, request: Request):
    # This endpoint is useful for seeing how input maps to safe key/cmd. Allow protected.
    try:
        _ = require_api_key(request)
    except HTTPException as e:
        raise e
    text = (payload.get("cmd") or "").strip()
    if not text:
        return {"error":"no cmd"}
    # naive normalization: small mapping examples
    normalized = text.lower().replace("dekho","show").replace("kede","which").strip()
    # simple translations back/forth not implemented here (keep small)
    # map to key
    mappings = {
        "services show": "list_services",
        "list services": "list_services",
        "show logs": "list_logs",
        "git status": "git_status"
    }
    mapped_key = mappings.get(normalized, None)
    mapped_cmd = map_command(mapped_key) if mapped_key else None
    return {
        "input": text,
        "normalized": normalized,
        "mapped_key": mapped_key,
        "mapped_cmd": mapped_cmd
    }

@app.post("/run")
async def run_command(payload: dict, request: Request):
    try:
        _ = require_api_key(request)
    except HTTPException as e:
        raise e
    cmd_text = (payload.get("cmd") or "").strip()
    if not cmd_text:
        raise HTTPException(status_code=400, detail="no cmd")
    # first check if it's a known key; else treat as raw mapped key
    key_map = {
        "services dekho": "list_services",
        "services show": "list_services",
        "list_services": "list_services",
        "show logs": "list_logs",
        "git status": "git_status"
    }
    key = key_map.get(cmd_text.lower(), None)
    cmd_to_run = None
    if key:
        cmd_to_run = map_command(key)
    else:
        # if user supplied a direct key or a direct shell command, prefer safe mapping only
        cmd_to_run = map_command(cmd_text)  # only allow whitelisted keys
    if not cmd_to_run:
        return JSONResponse(status_code=200, content={"error":"I didn't understand. Try phrases like 'services dekho', 'show logs', 'git status'."})
    # run
    res = await executor.run_shell(cmd_to_run)
    # Prepare safe preview lines (avoid backslashes inside f-string expressions)
    stdout_preview = (res.get("stdout") or "")[:800].replace("\n", " ")
    stderr_preview = (res.get("stderr") or "")[:800].replace("\n", " ")
    # log to file
    logs_dir = os.path.join(ROOT, "logs")
    os.makedirs(logs_dir, exist_ok=True)
    log_line = f"{time.asctime()} | cmd={cmd_text} | rc={res.get('returncode')} | stdout_preview={stdout_preview}\n"
    with open(os.path.join(logs_dir, "command_history.log"), "a", encoding="utf8") as f:
        f.write(log_line)
    return {
        "reply": f"Okay — running '{key}'.",
        "key": key,
        "result": res
    }

# small helper endpoint to prepare logs zip (used by UI)
@app.post("/__prepare_logs")
def prepare_logs(request: Request):
    try:
        _ = require_api_key(request)
    except HTTPException as e:
        raise e
    import shutil, datetime
    outdir = os.path.join(ROOT, "outbox")
    os.makedirs(outdir, exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = os.path.join(outdir, f"logs_bundle_{ts}.zip")
    logs_dir = os.path.join(ROOT, "logs")
    if not os.path.exists(logs_dir):
        return {"error":"no logs"}
    shutil.make_archive(dest[:-4], 'zip', logs_dir)
    return {"path": dest}
