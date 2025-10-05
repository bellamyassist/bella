# setup_bella.py
import secrets, pathlib

ROOT = pathlib.Path(__file__).resolve().parent
SCRIPTS_DIR = ROOT / "scripts"
FILES_DIR = ROOT / "files"
OUTBOX = ROOT / "outbox"

SCRIPTS_DIR.mkdir(exist_ok=True)
FILES_DIR.mkdir(exist_ok=True)
OUTBOX.mkdir(exist_ok=True)

# 1) Token
TOKEN_FILE = ROOT / "token.txt"
if not TOKEN_FILE.exists():
    token = secrets.token_urlsafe(24)
    TOKEN_FILE.write_text(token)
    print(f"Generated API token: {token}")
else:
    print("Token already exists at token.txt")

# 2) Sample scripts
(SCRIPTS_DIR / "hello.py").write_text('print("Hello from Bella script!")', encoding="utf-8")

(SCRIPTS_DIR / "long_task.py").write_text(
    "import time\n"
    "for i in range(5):\n"
    "    print(f'step {i+1}/5')\n"
    "    time.sleep(1)\n"
    "print('Long task done')\n",
    encoding="utf-8"
)

# Demo bats
start_bat = SCRIPTS_DIR / "start_ui.bat"
if not start_bat.exists():
    start_bat.write_text(
        f'@echo off\nREM Demo start UI server\n'
        f'start "Bella UI" cmd /k "venv\\Scripts\\activate.bat && cd /d {ROOT} && python -m http.server 5500"\n',
        encoding="utf-8"
    )
stop_bat = SCRIPTS_DIR / "stop_ui.bat"
if not stop_bat.exists():
    stop_bat.write_text(
        "@echo off\nREM Demo stop\n"
        "echo Please close the Bella UI window manually.\n",
        encoding="utf-8"
    )

# 3) Sample file
(FILES_DIR / "notes.txt").write_text("Bella notes\nPut editable notes here.\n", encoding="utf-8")

print("Setup complete: token, scripts, files ready.")
