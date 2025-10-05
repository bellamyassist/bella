# offload.py
import os, json, uuid, subprocess, shutil, time
from pathlib import Path

BASE = Path("C:/bella")
JOBS_DIR = BASE / "jobs"
RESULTS_DIR = BASE / "results"
OUTBOX = BASE / "outbox"
RCLONE_REMOTE = "bella_remote"   # <-- set to your rclone remote name
RCLONE_JOBS_REMOTE = f"{RCLONE_REMOTE}:jobs"
RCLONE_RESULTS_REMOTE = f"{RCLONE_REMOTE}:results"

for p in (JOBS_DIR, RESULTS_DIR, OUTBOX):
    p.mkdir(parents=True, exist_ok=True)

def has_cuda():
    try:
        import torch
        return torch.cuda.is_available()
    except Exception:
        return shutil.which("nvidia-smi") is not None

def create_job(payload: dict):
    job_id = payload.get("job_id") or f"job-{uuid.uuid4().hex[:8]}"
    payload["job_id"] = job_id
    payload["created_at"] = int(time.time())
    path = JOBS_DIR / f"{job_id}.json"
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    return str(path)

def push_jobs_to_remote():
    # rclone copy local jobs folder to remote jobs folder (only new files)
    cmd = ["rclone", "copy", str(JOBS_DIR), RCLONE_JOBS_REMOTE, "--update"]
    subprocess.run(cmd, check=True)

def pull_results_from_remote():
    cmd = ["rclone", "copy", RCLONE_RESULTS_REMOTE, str(RESULTS_DIR), "--update"]
    subprocess.run(cmd, check=True)

def run_local_job(jobfile_path: str):
    # runs a JSON job on the local machine (assumes venv python)
    with open(jobfile_path, "r", encoding="utf-8") as f:
        job = json.load(f)
    script = job.get("script")
    args = job.get("args", {})
    if not script:
        return {"error": "no script specified"}
    python_exe = Path("C:/bella/venv/Scripts/python.exe")
    cmd = [str(python_exe), script] + [f"--{k}={v}" for k,v in args.items()]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    outdir = RESULTS_DIR / job["job_id"]
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / "stdout.txt").write_text(proc.stdout or "", encoding="utf-8")
    (outdir / "stderr.txt").write_text(proc.stderr or "", encoding="utf-8")
    (outdir / "meta.json").write_text(json.dumps({"returncode": proc.returncode}), encoding="utf-8")
    return {"job": job["job_id"], "rc": proc.returncode, "result_dir": str(outdir)}
