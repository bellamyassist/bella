# nlp_pipeline.py - normalization + intent mapping + optional translator fallback
import re

# ------------------------------
# Intent Map (phrases -> safe keys)
# ------------------------------
INTENT_MAP = {
    # services
    "show services": "list_services",
    "services dekho": "list_services",
    "services dikhayo": "list_services",
    "kede services ne": "list_services",
    "which services are there": "list_services",
    "list services": "list_services",
    "list the services": "list_services",
    "show me services": "list_services",
    "services dikhao": "list_services",

    # logs
    "show logs": "list_logs",
    "logs dikhao": "list_logs",
    "logs dekho": "list_logs",
    "show me logs": "list_logs",
    "show the logs": "list_logs",

    # git
    "git status": "git_status",
    "show git status": "git_status",
    "git di halat daso": "git_status",

    # readme / docs
    "show readme": "show_readme",
    "readme dikhao": "show_readme",
    "read me": "show_readme",

    # system info
    "python version": "show_python",
    "pip version": "show_pip",
    "keda python version": "show_python",
    "python dikhao": "show_python",

    # synonyms & casual speech
    "dekho": "list_services",
    "dikhado": "list_services",
    "logs": "list_logs",
    "status": "git_status",
}

# ------------------------------
# Normalization regex patterns
# ------------------------------
NORMALIZE_MAP = {
    r'\b(dikh|dekh|dekho|dikhana|dikhado|dikhayi)\b': 'show',
    r'\b(sevices|serivces|servises)\b': 'services',
    r'\b(kede|keda|keda service|kede ne)\b': 'services',
    r'\b(logs|log)\b': 'logs',
    r'\b(halat|status|haalat)\b': 'status',
    r'\b(readme|read me)\b': 'readme',
    r'[^\w\s]': ' ',   # remove punctuation
}

# ------------------------------
# Optional translator (deep-translator)
# ------------------------------
try:
    from deep_translator import GoogleTranslator
    _DEEP_TRANSLATOR_AVAILABLE = True
except Exception:
    _DEEP_TRANSLATOR_AVAILABLE = False

# ------------------------------
# Helpers
# ------------------------------
def normalize_text(text: str) -> str:
    """Apply regex replacements and cleanup."""
    t = (text or "").lower()
    for patt, repl in NORMALIZE_MAP.items():
        t = re.sub(patt, repl, t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def map_to_key(text: str):
    """
    Map user text to a safe command key.
    1. Direct match in INTENT_MAP
    2. Normalized match
    3. Keyword heuristics
    """
    if not text:
        return None
    txt = text.lower().strip()

    # direct exact match
    if txt in INTENT_MAP and INTENT_MAP[txt]:
        return INTENT_MAP[txt]

    # normalized match
    norm = normalize_text(txt)
    if norm in INTENT_MAP and INTENT_MAP[norm]:
        return INTENT_MAP[norm]

    # keyword heuristics
    if "service" in norm or "services" in norm:
        return "list_services"
    if "log" in norm:
        return "list_logs"
    if "git" in norm or "status" in norm or "halat" in norm:
        return "git_status"
    if "readme" in norm:
        return "show_readme"
    if "python" in norm:
        return "show_python"
    if "pip" in norm:
        return "show_pip"

    return None

def translate_text_optional(text: str) -> str:
    """
    Use deep-translator to translate input to English if available.
    If not available or fails, return the original text.
    """
    if not _DEEP_TRANSLATOR_AVAILABLE:
        return text
    try:
        translated = GoogleTranslator(source='auto', target='en').translate(text)
        return translated
    except Exception:
        return text
