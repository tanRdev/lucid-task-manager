import { Search } from "lucide-react";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { ProcessTableNew } from "./components/ProcessTableNew";
import { Sidebar } from "./components/Sidebar";
import { SystemLoadCard } from "./components/SystemLoadCard";
import { useProcesses } from "./hooks/useProcesses";

const ASSUMED_TOTAL_MEMORY_GB = 16;
const ASSUMED_TOTAL_MEMORY_BYTES = ASSUMED_TOTAL_MEMORY_GB * 1024 * 1024 * 1024;

type FilterCategory = "all" | "system" | "user" | "unknown";

const FILTER_LABELS: Record<FilterCategory, string> = {
  all: "All Processes",
  system: "System",
  user: "User",
  unknown: "Unknown",
};

function App() {
  const { processes, loading, error } = useProcesses();
  const [activeFilter, setActiveFilter] = useState<FilterCategory>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [cpuHistory, setCpuHistory] = useState<number[]>([]);
  const [memoryHistory, setMemoryHistory] = useState<number[]>([]);
  const [processCountHistory, setProcessCountHistory] = useState<number[]>([]);

  const { cpuUsage, memoryUsage } = useMemo(() => {
    if (processes.length === 0) return { cpuUsage: 0, memoryUsage: 0 };

    const totalCpu = processes.reduce((sum, p) => sum + p.cpu_usage, 0);
    const totalMem = processes.reduce((sum, p) => sum + p.memory_bytes, 0);

    return {
      cpuUsage: Math.min(totalCpu, 100),
      memoryUsage: Math.min((totalMem / ASSUMED_TOTAL_MEMORY_BYTES) * 100, 100),
    };
  }, [processes]);

  useEffect(() => {
    if (processes.length === 0) return;
    setCpuHistory((prev) => [...prev, cpuUsage].slice(-12));
    setMemoryHistory((prev) => [...prev, memoryUsage].slice(-12));
    setProcessCountHistory((prev) => [...prev, processes.length].slice(-12));
  }, [cpuUsage, memoryUsage, processes.length]);

  const categoryCounts = useMemo(() => {
    const counts = { all: 0, system: 0, user: 0, unknown: 0 };
    for (const p of processes) {
      counts.all++;
      if (p.safety === "system") counts.system++;
      else if (p.safety === "user") counts.user++;
      else counts.unknown++;
    }
    return counts;
  }, [processes]);

  const filteredProcesses = useMemo(() => {
    let filtered = processes;
    if (activeFilter !== "all") {
      filtered = filtered.filter((p) => p.safety === activeFilter);
    }
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.description.toLowerCase().includes(q),
      );
    }
    return filtered;
  }, [processes, activeFilter, searchQuery]);

  if (loading) {
    return (
      <div
        className="flex items-center justify-center h-screen w-full"
        style={{ background: "#0A0A0B" }}
      >
        <span
          style={{
            fontFamily: "Geist",
            fontSize: 13,
            fontWeight: 500,
            color: "#6B6B70",
          }}
        >
          Loading processes...
        </span>
      </div>
    );
  }

  if (error) {
    return (
      <div
        className="flex items-center justify-center h-screen w-full"
        style={{ background: "#0A0A0B" }}
      >
        <span
          style={{
            fontFamily: "Geist",
            fontSize: 13,
            fontWeight: 500,
            color: "#EF4444",
          }}
        >
          Error: {error}
        </span>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-transparent">
      <Sidebar
        activeFilter={activeFilter}
        onFilterChange={(f) => setActiveFilter(f as FilterCategory)}
        counts={categoryCounts}
        cpuUsage={cpuUsage}
        memoryUsage={memoryUsage}
        totalMemoryGB={ASSUMED_TOTAL_MEMORY_GB}
      />

      <div
        className="flex-1 flex flex-col overflow-hidden"
        style={{ background: "#0A0A0B" }}
      >
        {/* Top Bar — process header */}
        <div
          className="flex items-center justify-between shrink-0"
          style={
            {
              height: 64,
              padding: "0 32px",
              borderBottom: "1px solid #1F1F23",
            } as React.CSSProperties
          }
        >
          <div
            className="flex items-center"
            style={{ gap: "16px" }}
          >
            <h1
              style={{
                fontFamily: "Geist",
                fontSize: 20,
                fontWeight: 600,
                color: "#FFFFFF",
                margin: 0,
              }}
            >
              {FILTER_LABELS[activeFilter]}
            </h1>
            <div
              className="flex items-center"
              style={{
                background: "#1A1A1D",
                borderRadius: 100,
                padding: "4px 10px",
              }}
            >
              <span
                style={{
                  fontFamily: "JetBrains Mono",
                  fontSize: 12,
                  color: "#8B8B90",
                }}
              >
                {filteredProcesses.length} processes
              </span>
            </div>
          </div>

          <div
            className="flex items-center"
          >
            <div
              className="flex items-center"
              style={{
                background: "#111113",
                border: "1px solid #2A2A2E",
                borderRadius: 8,
                height: 36,
                width: 280,
                padding: "0 12px",
                gap: 8,
              }}
            >
              <Search
                style={{
                  color: "#6B6B70",
                  width: 16,
                  height: 16,
                  flexShrink: 0,
                }}
              />
              <input
                type="text"
                placeholder="Search processes…"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  fontFamily: "Geist",
                  fontSize: 13,
                  color: "#FFFFFF",
                  background: "transparent",
                  border: "none",
                  outline: "none",
                  flex: 1,
                  height: "100%",
                }}
              />
              <span
                style={{
                  fontFamily: "JetBrains Mono",
                  fontSize: 11,
                  color: "#4A4A4E",
                  background: "#1A1A1D",
                  border: "1px solid #2A2A2E",
                  borderRadius: 4,
                  padding: "2px 6px",
                  flexShrink: 0,
                }}
              >
                ⌘K
              </span>
            </div>
          </div>
        </div>

        {/* Metrics Row */}
        <SystemLoadCard
          cpuUsage={cpuUsage}
          memoryUsage={memoryUsage}
          cpuHistory={cpuHistory}
          memoryHistory={memoryHistory}
          processCount={processes.length}
          processCountHistory={processCountHistory}
        />

        {/* Process Table */}
        <ProcessTableNew
          processes={filteredProcesses}
          totalCount={categoryCounts.all}
        />
      </div>
    </div>
  );
}

export default App;
