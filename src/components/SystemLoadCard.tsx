import { Cpu, GitBranch, MemoryStick, Wifi } from "lucide-react";

interface MetricsRowProps {
  cpuUsage: number;
  memoryUsage: number;
  cpuHistory: number[];
  memoryHistory: number[];
  processCount: number;
  processCountHistory: number[];
}

function BarSparkline({
  data,
  color,
  maxBars = 12,
}: {
  data: number[];
  color: string;
  maxBars?: number;
}) {
  const bars = data.slice(-maxBars);
  while (bars.length < maxBars) bars.unshift(0);

  const max = Math.max(...bars, 1);

  return (
    <div className="flex items-end w-full" style={{ gap: 2, height: 24 }}>
      {bars.map((value, i) => {
        const ratio = value / max;
        const height = Math.max(2, ratio * 22);
        // Opacity from hex alpha in Pencil: ranges ~0x40 (0.25) to ~0xB0 (0.69)
        const alpha = Math.round(0x30 + ratio * 0x80)
          .toString(16)
          .padStart(2, "0");
        return (
          <div
            key={`${i}-${value}`}
            className="flex-1"
            style={{
              height,
              borderRadius: "2px 2px 0 0",
              backgroundColor: `${color}${alpha}`,
            }}
          />
        );
      })}
    </div>
  );
}

interface MetricCardProps {
  label: string;
  icon: React.ReactNode;
  value: string;
  data: number[];
  color: string;
}

function MetricCard({ label, icon, value, data, color }: MetricCardProps) {
  return (
    <div
      className="flex flex-col gap-2"
      style={{
        background: "#111113",
        border: "1px solid #1F1F23",
        borderRadius: 12,
        padding: 12,
        minWidth: 0,
        overflow: "hidden",
      }}
    >
      {/* Header */}
      <div className="flex items-center justify-between w-full">
        <span
          style={{
            fontFamily: "JetBrains Mono",
            fontSize: 11,
            fontWeight: 600,
            letterSpacing: 0.5,
            color: "#6B6B70",
          }}
        >
          {label}
        </span>
        {icon}
      </div>

      {/* Value */}
      <span
        style={{
          fontFamily: "JetBrains Mono",
          fontSize: 24,
          fontWeight: 500,
          letterSpacing: -1,
          color: "#FFFFFF",
        }}
      >
        {value}
      </span>

      {/* Bar Sparkline */}
      <BarSparkline data={data} color={color} />
    </div>
  );
}

export function SystemLoadCard({
  cpuUsage,
  memoryUsage,
  cpuHistory,
  memoryHistory,
  processCount,
  processCountHistory,
}: MetricsRowProps) {
  const iconStyle = { color: "#6B6B70", width: 14, height: 14 };

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(4, minmax(0, 1fr))",
        gap: 16,
        padding: "20px 20px 0 20px",
        width: "100%",
      }}
    >
      <MetricCard
        label="CPU"
        icon={<Cpu style={iconStyle} />}
        value={`${cpuUsage.toFixed(1)}%`}
        data={cpuHistory}
        color="#FF5C00"
      />
      <MetricCard
        label="MEMORY"
        icon={<MemoryStick style={iconStyle} />}
        value={`${memoryUsage.toFixed(1)}%`}
        data={memoryHistory}
        color="#22C55E"
      />
      <MetricCard
        label="THREADS"
        icon={<GitBranch style={iconStyle} />}
        value={processCount.toLocaleString()}
        data={processCountHistory}
        color="#ADADB0"
      />
      <MetricCard
        label="NETWORK"
        icon={<Wifi style={iconStyle} />}
        value="—"
        data={[]}
        color="#B2B2FF"
      />
    </div>
  );
}
