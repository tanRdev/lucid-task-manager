import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import type { Safety } from "../types";

interface SafetyDotProps {
  safety: Safety;
}

const config: Record<Safety, { color: string; glow: string; label: string }> = {
  system: {
    color: "var(--lucid-success)",
    glow: "0 0 8px var(--lucid-success-glow), 0 0 12px rgba(6, 255, 165, 0.2)",
    label: "System Process — Do Not Kill",
  },
  user: {
    color: "var(--lucid-warning)",
    glow: "0 0 8px rgba(255, 214, 10, 0.4), 0 0 12px rgba(255, 214, 10, 0.2)",
    label: "User Application — Safe to Kill",
  },
  unknown: {
    color: "var(--lucid-danger)",
    glow: "0 0 8px rgba(255, 0, 110, 0.4), 0 0 12px rgba(255, 0, 110, 0.2)",
    label: "Unknown Process — Caution",
  },
};

export function SafetyDot({ safety }: SafetyDotProps) {
  const { color, glow, label } = config[safety];

  return (
    <TooltipProvider delayDuration={300}>
      <Tooltip>
        <TooltipTrigger asChild>
          <div className="flex items-center justify-center relative">
            <div
              className="w-2.5 h-2.5 rounded-full transition-all duration-200 hover:scale-125"
              style={{ backgroundColor: color, boxShadow: glow }}
            />
          </div>
        </TooltipTrigger>
        <TooltipContent
          side="right"
          className="lucid-glass-elevated text-[11px] font-bold px-3 py-2"
        >
          {label}
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
