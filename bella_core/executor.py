# executor.py - runs shell commands using subprocess in a thread (Windows-safe)
import asyncio
import subprocess
import os
from typing import Dict, Any

class Executor:
    def __init__(self, root: str):
        self.root = root

    async def run_shell(self, cmd: str, timeout: int = 120) -> Dict[str, Any]:
        """
        Run `cmd` in a thread using subprocess.run so it works reliably on Windows.
        Returns dict: {cmd, returncode, stdout, stderr}
        """
        cwd = self.root if self.root else None

        def _run():
            try:
                completed = subprocess.run(
                    cmd,
                    shell=True,
                    cwd=cwd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=timeout
                )
                stdout = completed.stdout.decode('utf-8', errors='replace')
                stderr = completed.stderr.decode('utf-8', errors='replace')
                return {
                    "cmd": cmd,
                    "returncode": completed.returncode,
                    "stdout": stdout,
                    "stderr": stderr
                }
            except subprocess.TimeoutExpired as te:
                return {"cmd": cmd, "returncode": -1, "stdout": "", "stderr": f"TimeoutExpired: {te}"}
            except Exception as e:
                return {"cmd": cmd, "returncode": -2, "stdout": "", "stderr": f"Exception: {e}"}

        result = await asyncio.to_thread(_run)

        # truncate very long outputs
        if isinstance(result.get("stdout"), str) and len(result["stdout"]) > 20000:
            result["stdout"] = result["stdout"][-20000:]
        if isinstance(result.get("stderr"), str) and len(result["stderr"]) > 20000:
            result["stderr"] = result["stderr"][-20000:]
        return result
