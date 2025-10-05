# llm_backend.py
# Adapter layer to talk to a local LLM. Start with Ollama (HTTP) or stub for GPT4All.
import os
import requests
import json
from typing import Dict, Any

# Config via env or defaults
LLM_BACKEND = os.environ.get("BELLA_LLM_BACKEND", "ollama")  # "ollama" or "gpt4all" or "local"
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")  # default ollama HTTP endpoint
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "mistral")  # change to your installed model name

def generate_with_ollama(prompt: str, max_tokens: int = 512, temperature: float = 0.2) -> Dict[str, Any]:
    url = f"{OLLAMA_URL}/api/generate"
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": False
    }
    r = requests.post(url, json=payload, timeout=60)
    r.raise_for_status()
    data = r.json()
    # Ollama returns content depending on model; adapt as necessary
    # Here we try to combine assistant outputs
    text = ""
    if isinstance(data, dict) and "completion" in data:
        text = data["completion"]
    else:
        # fallback parse
        text = json.dumps(data)
    return {"text": text, "raw": data}

def generate(prompt: str, max_tokens: int = 512, temperature: float = 0.2) -> Dict[str, Any]:
    if LLM_BACKEND == "ollama":
        return generate_with_ollama(prompt, max_tokens=max_tokens, temperature=temperature)
    else:
        # Placeholder: if you integrate GPT4All or llama.cpp, implement here.
        return {"text": "LLM backend not configured. Install Ollama or set BELLA_LLM_BACKEND.", "raw": {}}
