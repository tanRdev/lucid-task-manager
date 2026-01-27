import {
  Activity,
  HelpCircle,
  Layers,
  RefreshCw,
  Shield,
  User,
} from "lucide-react";
import type React from "react";

interface SidebarProps {
  activeFilter: string;
  onFilterChange: (filter: string) => void;
  counts: { all: number; system: number; user: number; unknown: number };
  cpuUsage: number;
  memoryUsage: number;
  totalMemoryGB: number;
}

const navItems = [
  { id: "all", label: "All Processes", icon: Layers },
  { id: "system", label: "System", icon: Shield },
  { id: "user", label: "User", icon: User },
  { id: "unknown", label: "Unknown", icon: HelpCircle },
];

export function Sidebar({
  activeFilter,
  onFilterChange,
  counts,
  cpuUsage,
  memoryUsage,
  totalMemoryGB,
}: SidebarProps) {
  const memUsedGB = (memoryUsage / 100) * totalMemoryGB;

  return (
    <div
      className="w-[260px] h-full flex flex-col justify-between shrink-0"
      style={{
        background: "#111113",
        borderRight: "1px solid #1F1F23",
      }}
    >
      {/* Sidebar Top */}
      <div className="flex flex-col">
        {/* Header — includes traffic lights space */}
        <div
          className="flex items-end h-16 shrink-0 px-5 pb-3"
          style={
            {
              borderBottom: "1px solid #1F1F23",
              WebkitAppRegion: "drag",
            } as React.CSSProperties
          }
        >
          <div
            className="flex items-center gap-[10px]"
            style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}
          >
            <Activity
              className="w-[22px] h-[22px]"
              style={{ color: "#FF5C00" }}
            />
            <span
              style={{
                fontFamily: "JetBrains Mono",
                fontSize: 16,
                fontWeight: 700,
                letterSpacing: 4,
                color: "#FFFFFF",
              }}
            >
              LUCID
            </span>
            <div
              className="w-[6px] h-[6px] rounded-full"
              style={{ background: "#22C55E" }}
            />
          </div>
        </div>

        {/* Nav Items */}
        <div className="flex flex-col gap-2" style={{ padding: "16px 12px" }}>
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeFilter === item.id;
            const count = counts[item.id as keyof typeof counts];

            return (
              <button
                key={item.id}
                type="button"
                onClick={() => onFilterChange(item.id)}
                className="flex items-center gap-3 h-10 w-full rounded-md px-3 transition-colors duration-200"
                style={{
                  background: isActive ? "#1A1A1D" : "transparent",
                  cursor: "pointer",
                  border: "none",
                  outline: "none",
                }}
              >
                <Icon
                  className="w-[18px] h-[18px]"
                  style={{ color: isActive ? "#FF5C00" : "#6B6B70" }}
                />
                <span
                  style={{
                    fontFamily: "Geist",
                    fontSize: 14,
                    fontWeight: isActive ? 500 : 400,
                    color: isActive ? "#FF5C00" : "#8B8B90",
                    flex: 1,
                    textAlign: "left",
                  }}
                >
                  {item.label}
                </span>
                <span
                  style={{
                    fontFamily: "JetBrains Mono",
                    fontSize: item.id === "all" ? 11 : 12,
                    color: "#6B6B70",
                  }}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {/* Divider */}
        <div className="h-px w-full" style={{ background: "#1F1F23" }} />

        {/* System Stats */}
        <div className="flex flex-col gap-3" style={{ padding: "16px 20px" }}>
          <span
            style={{
              fontFamily: "JetBrains Mono",
              fontSize: 11,
              fontWeight: 600,
              letterSpacing: 1,
              color: "#6B6B70",
            }}
          >
            SYSTEM OVERVIEW
          </span>

          {/* CPU Stat */}
          <div className="flex items-center justify-between w-full gap-2">
            <span
              style={{ fontFamily: "Geist", fontSize: 12, color: "#9CA3AF" }}
            >
              CPU Usage
            </span>
            <span
              style={{
                fontFamily: "JetBrains Mono",
                fontSize: 13,
                fontWeight: 500,
                color: "#FFFFFF",
              }}
            >
              {cpuUsage.toFixed(1)}%
            </span>
          </div>
          {/* CPU Bar */}
          <div
            className="w-full rounded-sm overflow-hidden"
            style={{ background: "#1A1A1D", height: 4 }}
          >
            <div
              className="h-full rounded-sm"
              style={{
                background: "#FF5C00",
                width: `${Math.min(cpuUsage, 100)}%`,
                transition: "width 300ms ease",
              }}
            />
          </div>

          {/* Memory Stat */}
          <div className="flex items-center justify-between w-full gap-2">
            <span
              style={{ fontFamily: "Geist", fontSize: 12, color: "#9CA3AF" }}
            >
              Memory
            </span>
            <span
              style={{
                fontFamily: "JetBrains Mono",
                fontSize: 13,
                fontWeight: 500,
                color: "#FFFFFF",
              }}
            >
              {memUsedGB.toFixed(1)} / {totalMemoryGB} GB
            </span>
          </div>
          {/* Memory Bar */}
          <div
            className="w-full rounded-sm overflow-hidden"
            style={{ background: "#1A1A1D", height: 4 }}
          >
            <div
              className="h-full rounded-sm"
              style={{
                background: "#FF8A4C",
                width: `${Math.min(memoryUsage, 100)}%`,
                transition: "width 300ms ease",
              }}
            />
          </div>
        </div>
      </div>

      {/* Sidebar Bottom */}
      <div
        className="flex flex-col gap-3"
        style={{
          padding: "16px 20px",
          borderTop: "1px solid #1F1F23",
        }}
      >
        <div className="flex items-center gap-2">
          <RefreshCw
            className="w-[14px] h-[14px]"
            style={{ color: "#22C55E" }}
          />
          <span style={{ fontFamily: "Geist", fontSize: 12, color: "#22C55E" }}>
            Live — refreshing every 2s
          </span>
        </div>
        <span style={{ fontFamily: "Geist", fontSize: 11, color: "#4A4A4E" }}>
          Lucid v1.0.0 — macOS 15.2
        </span>
      </div>
    </div>
  );
}
