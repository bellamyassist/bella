@echo off
setlocal

REM 1) Create venv
if not exist venv (
    python -m venv venv
)

echo Activating venv...
call venv\Scripts\activate.bat

echo Upgrading pip...
python -m pip install --upgrade pip

echo Installing python requirements...
python -m pip install -r requirements.txt

REM Create basic folders
if not exist jobs mkdir jobs
if not exist results mkdir results
if not exist outbox mkdir outbox
if not exist neuro mkdir neuro

REM Create a sample backtest runner (if not present)
if not exist neuro\backtest_runner.py (
  echo Creating sample backtest runner...
  > neuro\backtest_runner.py echo import sys, time, argparse
  >> neuro\backtest_runner.py echo parser=argparse.ArgumentParser()
  >> neuro\backtest_runner.py echo parser.add_argument("--strategy", default="v1")
  >> neuro\backtest_runner.py echo parser.add_argument("--start", default="2023-01-01")
  >> neuro\backtest_runner.py echo parser.add_argument("--end", default="2023-12-31")
  >> neuro\backtest_runner.py echo args=parser.parse_args()
  >> neuro\backtest_runner.py echo print("Running backtest", args.strategy, args.start, args.end)
  >> neuro\backtest_runner.py echo time.sleep(2)
  >> neuro\backtest_runner.py echo open("C:/bella/results/result-sample.txt","w").write("ok")
)

REM Create config if not present
if not exist bella_config.json (
  echo {"llm":"ollama","ollama_url":"http://127.0.0.1:11434","openai_model":"gpt-4"} > bella_config.json
)

REM Ensure token exists
python - <<PY
from pathlib import Path
p=Path("C:/bella/token.txt")
if not p.exists():
    p.write_text(__import__("secrets").token_urlsafe(28))
print("Token at:", p)
PY

echo Starting backend in separate window...
start "Bella Backend" cmd /k "cd /d C:\bella && venv\Scripts\activate.bat && python -m uvicorn main:app --reload"

echo Starting simple UI server for static UI (if using ui.html)
start "Bella UI" cmd /k "cd /d C:\bella && venv\Scripts\activate.bat && python -m http.server 5500 --bind 127.0.0.1"

echo Done. Backend: http://127.0.0.1:8000  UI: http://127.0.0.1:5500/ui.html
endlocal
pause
