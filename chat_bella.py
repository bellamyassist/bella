# chat_bella.py
import os, json
from pathlib import Path

BASE = Path("C:/bella")
CFG = BASE / "bella_config.json"

def load_config():
    cfg = {}
    if CFG.exists():
        cfg = json.loads(CFG.read_text(encoding="utf-8"))
    else:
        cfg = {
            "llm": "ollama",    # default: 'ollama' or 'openai'
            "ollama_url": "http://127.0.0.1:11434",
            "openai_model": "gpt-4",
            "openai_key_env": "OPENAI_API_KEY"
        }
        CFG.write_text(json.dumps(cfg, indent=2))
    return cfg

cfg = load_config()

def chat_with_llm(prompt: str, model: str = None):
    """
    High level adapter:
      - If model == 'openai' -> use OpenAI (if key exists)
      - If model == 'ollama' -> use Ollama local
      - Else -> use cfg['llm'] default
    """
    chosen = model or cfg.get("llm", "ollama")
    if chosen == "openai":
        return chat_openai(prompt)
    else:
        return chat_ollama(prompt)

# ---- OpenAI adapter ----
def chat_openai(prompt: str):
    key = os.environ.get(cfg.get("openai_key_env","OPENAI_API_KEY"))
    if not key:
        raise RuntimeError("OpenAI API key not found in environment")
    try:
        import openai
        openai.api_key = key
        res = openai.ChatCompletion.create(
            model=cfg.get("openai_model","gpt-4"),
            messages=[{"role":"user","content":prompt}],
            max_tokens=700,
            temperature=0.2
        )
        return res.choices[0].message.content.strip()
    except Exception as e:
        raise

# ---- Ollama / local HTTP adapter ----
def chat_ollama(prompt: str):
    # Ollama HTTP API simple POST (assuming ollama running with a model 'mistral' or similar)
    import requests
    url = cfg.get("ollama_url","http://127.0.0.1:11434") + "/api/generate"
    payload = {
        "model": "mistral",   # pick local model name (adjust if different)
        "prompt": prompt,
        "max_tokens": 512
    }
    try:
        r = requests.post(url, json=payload, timeout=20)
        r.raise_for_status()
        j = r.json()
        # Ollama's response shape may vary - this is a best-effort parse
        if isinstance(j, dict):
            if "text" in j:
                return j["text"]
            if "outputs" in j and j["outputs"]:
                return j["outputs"][0].get("content", j["outputs"][0]).get("text","")
        return str(j)
    except Exception as e:
        raise RuntimeError("Ollama request failed: " + str(e))
