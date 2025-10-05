#!/usr/bin/env python3
# report_failures.py - collect install logs and POST to Bella /upload endpoint (you must enable it)
import os, glob, json, requests
root = r"C:\bella"
logdir = os.path.join(root, "logs")
api = "http://127.0.0.1:8000/upload_log"  # backend must accept this
api_key = None
# try fetch local key
try:
    r = requests.get("http://127.0.0.1:8000/__get_local_api_key", timeout=3)
    api_key = r.json().get("api_key")
except Exception:
    api_key = None

def gather_logs():
    out = {}
    for p in glob.glob(os.path.join(logdir, "*.log")):
        name = os.path.basename(p)
        try:
            with open(p, "r", encoding="utf-8") as f:
                out[name] = f.read()[-20000:]  # last 20k chars
        except Exception as e:
            out[name] = f"Error reading: {e}"
    return out

logs = gather_logs()
payload = {"host": os.getenv("COMPUTERNAME"), "logs": logs}
if api_key:
    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        r = requests.post(api, json=payload, headers=headers, timeout=10)
        print("Posted logs:", r.status_code, r.text)
    except Exception as e:
        print("Failed to post logs:", e)
else:
    print("No local API key; write logs to file for manual copy")
    with open(os.path.join(root, "logs", "collected_install_report.json"), "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print("Wrote collected_install_report.json")
