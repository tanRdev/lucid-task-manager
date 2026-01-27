import { useVirtualizer } from "@tanstack/react-virtual";
import { Effect } from "effect";
import { MoreVertical } from "lucide-react";
import type React from "react";
import { useMemo, useRef, useState } from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { runtime } from "@/lib/runtime";
import { killProcess } from "@/services/commands";
import type { ProcessInfo } from "@/types";

interface ProcessTableProps {
  processes: ProcessInfo[];
  totalCount: number;
}

type SortField = "name" | "description" | "cpu_usage" | "memory_bytes";
type SortDirection = "asc" | "desc";

const ASSUMED_TOTAL_MEMORY_BYTES = 16 * 1024 * 1024 * 1024;

const SORT_FIELD_LABELS: Record<SortField, string> = {
  cpu_usage: "CPU %",
  memory_bytes: "MEM %",
  name: "Name",
  description: "Description",
};

function CategoryBadge({ safety }: { safety: string }) {
  const config: Record<string, { label: string; color: string; bg: string }> = {
    system: { label: "System", color: "#22C55E", bg: "#22C55E18" },
    user: { label: "User", color: "#FF8A4C", bg: "#FF5C0018" },
    unknown: { label: "Unknown", color: "#8B8B90", bg: "#ADADB018" },
  };
  const { label, color, bg } = config[safety] || config.unknown;

  return (
    <span
      style={{
        fontFamily: "JetBrains Mono",
        fontSize: 11,
        fontWeight: 500,
        color,
        background: bg,
        borderRadius: 100,
        padding: "3px 8px",
        whiteSpace: "nowrap",
      }}
    >
      {label}
    </span>
  );
}

export function ProcessTableNew({ processes, totalCount }: ProcessTableProps) {
  const [sortField, setSortField] = useState<SortField>("cpu_usage");
  const [sortDirection, setSortDirection] = useState<SortDirection>("desc");
  const [killTarget, setKillTarget] = useState<{
    pid: number;
    name: string;
  } | null>(null);

  const sortedProcesses = useMemo(() => {
    return [...processes].sort((a, b) => {
      const aVal = a[sortField];
      const bVal = b[sortField];
      if (typeof aVal === "string" && typeof bVal === "string") {
        return sortDirection === "asc"
          ? aVal.localeCompare(bVal)
          : bVal.localeCompare(aVal);
      }
      if (typeof aVal === "number" && typeof bVal === "number") {
        return sortDirection === "asc" ? aVal - bVal : bVal - aVal;
      }
      return 0;
    });
  }, [processes, sortField, sortDirection]);

  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: sortedProcesses.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 44,
    overscan: 10,
  });

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortField(field);
      setSortDirection("desc");
    }
  };

  const handleKill = (pid: number, name: string, safety: string) => {
    if (safety === "system") return;
    setKillTarget({ pid, name });
  };

  const confirmKill = () => {
    if (!killTarget) return;
    const effect = killProcess(killTarget.pid).pipe(
      Effect.catchAll((error) =>
        Effect.sync(() => {
          alert(`Failed to kill process: ${error.message}`);
        }),
      ),
    );
    runtime.runPromise(effect);
    setKillTarget(null);
  };

  const getMemPercent = (bytes: number) =>
    (bytes / ASSUMED_TOTAL_MEMORY_BYTES) * 100;

  const getCpuColor = (cpu: number) => (cpu >= 5 ? "#FF5C00" : "#ADADB0");
  const getCpuWeight = (cpu: number): number => (cpu >= 5 ? 500 : 400);

  const getMemColor = (bytes: number) => {
    const pct = getMemPercent(bytes);
    if (pct >= 8) return "#EF4444";
    if (pct >= 4) return "#FF5C00";
    return "#ADADB0";
  };

  const getMemWeight = (bytes: number): number => {
    const pct = getMemPercent(bytes);
    return pct >= 4 ? 500 : 400;
  };

  const getRowBg = (process: ProcessInfo) =>
    process.cpu_usage >= 8 ? "#FF5C0010" : "transparent";

  const getNameColor = (process: ProcessInfo) =>
    process.cpu_usage >= 8 ? "#FF5C00" : "#FFFFFF";

  // Column grid: 240px PROCESS, 1fr DESC, 120px CATEGORY, 90px CPU, 90px MEM, 80px PID, 60px ACTIONS
  const gridTemplate = "240px 1fr 120px 90px 90px 80px 60px";

  const headerCellStyle: React.CSSProperties = {
    fontFamily: "JetBrains Mono",
    fontSize: 11,
    fontWeight: 600,
    letterSpacing: 0.5,
    color: "#6B6B70",
    display: "flex",
    alignItems: "center",
    height: "100%",
    padding: "0 16px",
    cursor: "pointer",
    userSelect: "none",
    whiteSpace: "nowrap",
    background: "none",
    border: "none",
  };

  return (
    <>
      {/* Table Area */}
      <div
        className="flex-1 flex flex-col overflow-hidden"
        style={{ padding: "16px 32px 0 32px" }}
      >
        <div
          className="flex-1 flex flex-col overflow-hidden"
          style={{
            background: "#111113",
            border: "1px solid #1F1F23",
            borderRadius: 12,
          }}
        >
          {/* Table Header */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: gridTemplate,
              background: "#0D0D0E",
              height: 44,
              borderBottom: "1px solid #1F1F23",
              flexShrink: 0,
            }}
          >
            <button
              type="button"
              onClick={() => handleSort("name")}
              style={headerCellStyle}
            >
              PROCESS
            </button>
            <button
              type="button"
              onClick={() => handleSort("description")}
              style={headerCellStyle}
            >
              DESCRIPTION
            </button>
            <div style={{ ...headerCellStyle, cursor: "default" }}>
              CATEGORY
            </div>
            <button
              type="button"
              onClick={() => handleSort("cpu_usage")}
              style={{ ...headerCellStyle, justifyContent: "flex-end" }}
            >
              CPU %
            </button>
            <button
              type="button"
              onClick={() => handleSort("memory_bytes")}
              style={{ ...headerCellStyle, justifyContent: "flex-end" }}
            >
              MEM %
            </button>
            <div
              style={{
                ...headerCellStyle,
                justifyContent: "flex-end",
                cursor: "default",
              }}
            >
              PID
            </div>
            <div
              style={{
                ...headerCellStyle,
                justifyContent: "center",
                cursor: "default",
                fontSize: 16,
                fontFamily: "Geist",
                fontWeight: 600,
              }}
            >
              ⋮
            </div>
          </div>

          {/* Table Body — Virtualized */}
          <div ref={parentRef} className="flex-1 overflow-auto">
            <div
              style={{
                height: `${virtualizer.getTotalSize()}px`,
                width: "100%",
                position: "relative",
              }}
            >
              {virtualizer.getVirtualItems().map((virtualRow) => {
                const process = sortedProcesses[virtualRow.index];
                const memPct = getMemPercent(process.memory_bytes);

                return (
                  <div
                    key={process.pid}
                    className="group"
                    style={{
                      display: "grid",
                      gridTemplateColumns: gridTemplate,
                      alignItems: "center",
                      height: 44,
                      position: "absolute",
                      top: 0,
                      left: 0,
                      width: "100%",
                      transform: `translateY(${virtualRow.start}px)`,
                      borderBottom: "1px solid #1F1F23",
                      background: getRowBg(process),
                    }}
                  >
                    {/* Process Name */}
                    <div
                      className="truncate"
                      style={{
                        padding: "0 16px",
                        fontFamily: "JetBrains Mono",
                        fontSize: 13,
                        fontWeight: 500,
                        color: getNameColor(process),
                      }}
                    >
                      {process.name}
                    </div>

                    {/* Description */}
                    <div
                      className="truncate"
                      style={{
                        padding: "0 16px",
                        fontFamily: "Geist",
                        fontSize: 13,
                        color:
                          process.description === "Unknown Process"
                            ? "#6B6B70"
                            : "#ADADB0",
                        fontStyle:
                          process.description === "Unknown Process"
                            ? "italic"
                            : "normal",
                      }}
                    >
                      {process.description}
                    </div>

                    {/* Category Badge */}
                    <div
                      className="flex items-center"
                      style={{ padding: "0 16px" }}
                    >
                      <CategoryBadge safety={process.safety} />
                    </div>

                    {/* CPU % */}
                    <div
                      style={{
                        padding: "0 16px",
                        textAlign: "right",
                        fontFamily: "JetBrains Mono",
                        fontSize: 13,
                        fontWeight: getCpuWeight(process.cpu_usage),
                        color: getCpuColor(process.cpu_usage),
                      }}
                    >
                      {process.cpu_usage.toFixed(1)}
                    </div>

                    {/* MEM % */}
                    <div
                      style={{
                        padding: "0 16px",
                        textAlign: "right",
                        fontFamily: "JetBrains Mono",
                        fontSize: 13,
                        fontWeight: getMemWeight(process.memory_bytes),
                        color: getMemColor(process.memory_bytes),
                      }}
                    >
                      {memPct.toFixed(1)}
                    </div>

                    {/* PID */}
                    <div
                      style={{
                        padding: "0 16px",
                        textAlign: "right",
                        fontFamily: "JetBrains Mono",
                        fontSize: 13,
                        color: "#6B6B70",
                      }}
                    >
                      {process.pid}
                    </div>

                    {/* Actions */}
                    <div
                      className="flex items-center justify-center"
                      style={{ padding: "0 16px" }}
                    >
                      <button
                        type="button"
                        onClick={() =>
                          handleKill(process.pid, process.name, process.safety)
                        }
                        className="opacity-0 group-hover:opacity-100 transition-opacity"
                        style={{
                          background: "none",
                          border: "none",
                          cursor:
                            process.safety === "system" ? "default" : "pointer",
                          padding: 0,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        <MoreVertical
                          style={{ color: "#4A4A4E", width: 16, height: 16 }}
                        />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Table Footer */}
          <div
            className="flex items-center justify-between shrink-0"
            style={{
              background: "#0D0D0E",
              height: 40,
              padding: "0 16px",
              borderTop: "1px solid #1F1F23",
            }}
          >
            <span
              style={{ fontFamily: "Geist", fontSize: 12, color: "#6B6B70" }}
            >
              Showing {sortedProcesses.length} of {totalCount} processes
            </span>
            <div className="flex items-center gap-1">
              <span
                style={{
                  fontFamily: "Geist",
                  fontSize: 12,
                  color: "#6B6B70",
                }}
              >
                Sorted by:
              </span>
              <span
                style={{
                  fontFamily: "JetBrains Mono",
                  fontSize: 12,
                  fontWeight: 500,
                  color: "#FF5C00",
                }}
              >
                {SORT_FIELD_LABELS[sortField]} ({sortDirection})
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Kill Confirmation Dialog */}
      <AlertDialog
        open={killTarget !== null}
        onOpenChange={(open) => {
          if (!open) setKillTarget(null);
        }}
      >
        <AlertDialogContent className="lucid-glass-elevated">
          <AlertDialogHeader>
            <AlertDialogTitle>Terminate Process</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to kill{" "}
              <span className="font-semibold">{killTarget?.name}</span> (PID:{" "}
              {killTarget?.pid})? This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmKill}
              style={{ background: "#EF4444", color: "#FFFFFF" }}
            >
              Kill Process
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
