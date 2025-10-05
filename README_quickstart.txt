Bella quickstart (local LLM)

1) Prerequisites:
 - Windows with Python 3.10+
 - Optional: install Ollama (recommended) or GPT4All for local LLM.

2) To install Ollama (recommended):
 - Download Ollama for Windows and follow their instructions.
 - Run Ollama and install a model (e.g., mistral) so that the endpoint http://127.0.0.1:11434/api/generate works.

3) Install & start Bella:
 - Open cmd.exe (Administrator not required)
 - cd \bella
 - install_and_start_all.bat

4) Open UI:
 - http://127.0.0.1:5500/ui.html

5) Token:
 - Token is printed at install and saved to token.txt. Copy it into UI if needed.

6) Use:
 - In UI ask natural language questions; Bella will use local LLM (if available) to respond.
 - Use Self Heal to run diagnostics.

Security:
 - Bella listens on 127.0.0.1 only.
 - Keep token.txt secret.

If you want cloud LLM integration later, provide OpenAI API key and we can add hybrid mode.
