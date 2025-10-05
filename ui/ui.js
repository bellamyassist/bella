// C:\bella\ui\ui.js
const API = "http://127.0.0.1:8000";

async function getLocalKey() {
  try {
    const r = await fetch(API + "/__get_local_api_key");
    if (!r.ok) throw new Error("no key");
    const j = await r.json();
    return j.api_key;
  } catch (e) {
    console.error("getLocalKey failed", e);
    return null;
  }
}

async function fetchHealth() {
  try {
    const r = await fetch(API + "/metrics");
    if (!r.ok) { document.getElementById("health").textContent = "metrics unavailable"; return; }
    const j = await r.json();
    document.getElementById("health").textContent = `CPU ${j.cpu_percent}% • RAM ${j.mem_percent}% • Disk ${j.disk_percent}%`;
  } catch (e) {
    document.getElementById("health").textContent = "backend unreachable";
  }
}

async function runCommand() {
  const cmd = document.getElementById("cmdInput").value || "services dekho";
  const key = await getLocalKey();
  if (!key) { alert("No API key available — start backend"); return; }
  document.getElementById("cmdOutput").textContent = "Running...";
  try {
    const r = await fetch(API + "/run", {
      method: "POST",
      headers: {"Authorization": "Bearer " + key, "Content-Type":"application/json"},
      body: JSON.stringify({cmd})
    });
    const j = await r.json();
    document.getElementById("cmdOutput").textContent = JSON.stringify(j, null, 2);
    loadHistory();
  } catch (e) {
    document.getElementById("cmdOutput").textContent = "Error: " + e;
  }
}

let sseSource = null;
async function streamRun() {
  if (sseSource) {
    sseSource.close();
    sseSource = null;
    return;
  }
  const cmd = document.getElementById("cmdInput").value || "services dekho";
  const key = await getLocalKey();
  if (!key) { alert("No API key available — start backend"); return; }
  // open an EventSource-like via fetch streaming (SSE polyfill)
  const url = API + "/stream_run";
  document.getElementById("cmdOutput").textContent = "Streaming… (click Stream again to stop)";
  // Using fetch + reader to support Authorization header
  const res = await fetch(url, {
    method: "POST",
    headers: {"Authorization":"Bearer " + key, "Content-Type":"application/json"},
    body: JSON.stringify({cmd})
  });
  if (!res.ok) {
    const txt = await res.text();
    document.getElementById("cmdOutput").textContent = "Error: " + txt;
    return;
  }
  const reader = res.body.getReader();
  sseSource = {
    close() { reader.cancel(); sseSource = null; }
  };
  const decoder = new TextDecoder();
  let acc = "";
  while (true) {
    const {done, value} = await reader.read();
    if (done) break;
    acc += decoder.decode(value || new Uint8Array(), {stream:true});
    // parse SSE 'data: ...'
    const parts = acc.split("\n\n");
    for (let i = 0; i < parts.length - 1; i++) {
      const message = parts[i];
      const lines = message.split("\n");
      for (const ln of lines) {
        if (ln.startsWith("data:")) {
          const payload = ln.slice(5).trim();
          if (payload === "[STREAM-END]") {
            document.getElementById("cmdOutput").textContent += "\n--- stream ended";
            if (sseSource) { sseSource.close(); }
            return;
          }
          document.getElementById("cmdOutput").textContent += payload + "\n";
        }
      }
    }
    acc = parts[parts.length - 1];
  }
}

// Service controls
async function svcAction(action) {
  const svc = document.getElementById("svcSelect").value;
  const key = await getLocalKey();
  if (!key) { alert("No API key"); return; }
  document.getElementById("svcOutput").textContent = `${action} ${svc}…`;
  try {
    const r = await fetch(`${API}/service/${action}`, {
      method: "POST",
      headers: {"Authorization":"Bearer " + key, "Content-Type":"application/json"},
      body: JSON.stringify({service: svc})
    });
    const j = await r.json();
    document.getElementById("svcOutput").textContent = JSON.stringify(j, null, 2);
    loadHistory();
  } catch (e) {
    document.getElementById("svcOutput").textContent = "Error: " + e;
  }
}

// History & logs
async function loadHistory() {
  const key = await getLocalKey();
  if (!key) { document.getElementById("history").textContent = "(no key)"; return; }
  try {
    const r = await fetch(`${API}/show_log?file=command_history.log`, {headers:{"Authorization":"Bearer " + key}});
    if (!r.ok) { document.getElementById("history").textContent = "(no history)"; return; }
    const txt = await r.text();
    document.getElementById("history").textContent = txt || "(empty)";
  } catch (e) {
    document.getElementById("history").textContent = "Could not fetch history";
  }
}

async function loadLog() {
  const file = document.getElementById("logSelect").value;
  const key = await getLocalKey();
  if (!key) { document.getElementById("logOutput").textContent = "(no key)"; return; }
  try {
    const r = await fetch(`${API}/show_log?file=${encodeURIComponent(file)}`, {headers:{"Authorization":"Bearer " + key}});
    if (!r.ok) { document.getElementById("logOutput").textContent = "(log not found)"; return; }
    const txt = await r.text();
    document.getElementById("logOutput").textContent = txt || "(empty)";
  } catch (e) {
    document.getElementById("logOutput").textContent = "Could not fetch log";
  }
}

let tailInterval = null;
async function tailLog() {
  if (tailInterval) { clearInterval(tailInterval); tailInterval = null; document.getElementById("logOutput").textContent += "\n(stopped tail)"; return; }
  const file = document.getElementById("logSelect").value;
  const key = await getLocalKey();
  if (!key) { document.getElementById("logOutput").textContent = "(no key)"; return; }
  tailInterval = setInterval(async () => {
    try {
      const r = await fetch(`${API}/show_log?file=${encodeURIComponent(file)}`, {headers:{"Authorization":"Bearer " + key}});
      if (r.ok) {
        const txt = await r.text();
        document.getElementById("logOutput").textContent = txt;
      }
    } catch (e) {}
  }, 2000);
}

// File manager / editor functions
async function listFiles() {
  const path = document.getElementById("pathInput").value || "";
  try {
    const r = await fetch(`${API}/list_files?path=${encodeURIComponent(path)}`);
    if (!r.ok) { document.getElementById("fileList").textContent = "Could not list"; return; }
    const j = await r.json();
    const lines = j.items.map(i => (i.is_dir ? "[DIR] " : "     ") + i.name).join("\n");
    document.getElementById("fileList").textContent = lines || "(empty)";
  } catch (e) {
    document.getElementById("fileList").textContent = "Error listing files";
  }
}

async function readFile() {
  const path = document.getElementById("editPath").value;
  if (!path) { alert("Enter path"); return; }
  const key = await getLocalKey();
  if (!key) { alert("No key"); return; }
  try {
    const r = await fetch(`${API}/read_file?path=${encodeURIComponent(path)}`, {headers:{"Authorization":"Bearer " + key}});
    if (!r.ok) { document.getElementById("editor").value = "(not found)"; return; }
    const txt = await r.text();
    document.getElementById("editor").value = txt;
  } catch (e) {
    document.getElementById("editor").value = "Error reading file";
  }
}

async function saveFile() {
  const path = document.getElementById("editPath").value;
  const content = document.getElementById("editor").value;
  if (!path) { alert("Enter path"); return; }
  const key = await getLocalKey();
  if (!key) { alert("No key"); return; }
  try {
    const r = await fetch(`${API}/write_file`, {
      method: "POST",
      headers: {"Authorization":"Bearer " + key, "Content-Type":"application/json"},
      body: JSON.stringify({path, content})
    });
    const j = await r.json();
    alert("Saved: " + j.path);
    listFiles();
  } catch (e) { alert("Save error: " + e); }
}

// initial load
fetchHealth();
loadHistory();
setInterval(fetchHealth, 5000);
