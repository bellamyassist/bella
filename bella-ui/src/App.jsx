import { useState, useEffect } from "react";
import axios from "axios";
import { motion } from "framer-motion";
import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

function App() {
  const [input, setInput] = useState("");
  const [response, setResponse] = useState("");
  const [logs, setLogs] = useState([]);
  const [chartData, setChartData] = useState({
    labels: ["Mon", "Tue", "Wed", "Thu", "Fri"],
    datasets: [
      {
        label: "System Load",
        data: [12, 19, 7, 15, 22],
        borderColor: "#10B981",
        backgroundColor: "rgba(16,185,129,0.2)",
      },
    ],
  });

  // Fetch logs every 5s
  useEffect(() => {
    const fetchLogs = async () => {
      try {
        const res = await axios.get("http://127.0.0.1:8000/api/logs");
        setLogs(res.data.logs.slice(-6)); // last 6 log lines
      } catch (err) {
        console.error("Error fetching logs:", err.message);
      }
    };
    fetchLogs();
    const interval = setInterval(fetchLogs, 5000);
    return () => clearInterval(interval);
  }, []);

  const sendCommand = async () => {
    try {
      const res = await axios.post("http://127.0.0.1:8000/api/chat", {
        message: input,
      });
      setResponse(res.data.reply || "No response");
    } catch (err) {
      setResponse("Error: " + err.message);
    }
  };

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-900 text-white">
      {/* Sidebar */}
      <div className="w-60 bg-black/30 backdrop-blur-xl p-6 border-r border-gray-700 flex flex-col">
        <h2 className="text-2xl font-bold text-green-400 mb-8">⚡ Bella</h2>
        <nav className="flex flex-col gap-4">
          <button className="hover:text-green-400">Dashboard</button>
          <button className="hover:text-green-400">Bella</button>
          <button className="hover:text-green-400">Fusion</button>
          <button className="hover:text-green-400">Neuro</button>
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 p-8 space-y-6 overflow-y-auto">
        <h1 className="text-3xl font-bold">Assistant Dashboard</h1>

        {/* Top Cards */}
        <div className="grid grid-cols-3 gap-6">
          <motion.div
            whileHover={{ scale: 1.03 }}
            className="bg-white/5 rounded-xl p-6 shadow-lg border border-gray-700"
          >
            <h2 className="text-lg font-semibold">System Health</h2>
            <p className="text-green-400 text-2xl mt-2">✅ Online</p>
          </motion.div>

          <motion.div
            whileHover={{ scale: 1.03 }}
            className="bg-white/5 rounded-xl p-6 shadow-lg border border-gray-700"
          >
            <h2 className="text-lg font-semibold">Active Modules</h2>
            <p className="text-blue-400 text-2xl mt-2">Bella + Backend</p>
          </motion.div>

          <motion.div
            whileHover={{ scale: 1.03 }}
            className="bg-white/5 rounded-xl p-6 shadow-lg border border-gray-700"
          >
            <h2 className="text-lg font-semibold">Requests</h2>
            <p className="text-purple-400 text-2xl mt-2">{logs.length * 3}</p>
          </motion.div>
        </div>

        {/* Chart + Logs */}
        <div className="grid grid-cols-2 gap-6">
          <div className="bg-white/5 rounded-xl p-6 border border-gray-700">
            <h2 className="text-lg font-semibold mb-2">System Load</h2>
            <Line data={chartData} />
          </div>

          <div className="bg-white/5 rounded-xl p-6 border border-gray-700">
            <h2 className="text-lg font-semibold mb-2">Recent Logs</h2>
            <ul className="text-sm text-gray-300 space-y-1">
              {logs.map((log, i) => (
                <li key={i}>• {log}</li>
              ))}
            </ul>
          </div>
        </div>

        {/* Chat */}
        <div className="bg-white/5 rounded-xl p-6 border border-gray-700">
          <h2 className="text-lg font-semibold mb-4">Chat with Bella</h2>
          <div className="flex gap-2">
            <input
              className="flex-1 p-2 rounded text-black"
              placeholder="Ask Bella..."
              value={input}
              onChange={(e) => setInput(e.target.value)}
            />
            <button
              onClick={sendCommand}
              className="bg-green-600 px-4 py-2 rounded hover:bg-green-700"
            >
              Send
            </button>
          </div>
          <div className="mt-4 p-4 bg-gray-800 rounded">
            <strong>Response:</strong>
            <p>{response}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
