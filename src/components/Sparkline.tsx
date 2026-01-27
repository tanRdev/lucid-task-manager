import { useMemo } from "react";

interface SparklineProps {
  data: number[];
  accentColor?: string;
  label?: string;
}

/**
 * Catmull-Rom to cubic bezier conversion for smooth SVG curves.
 */
function catmullRomPath(points: [number, number][], tension = 0.3): string {
  if (points.length < 2) return "";
  if (points.length === 2) {
    return `M ${points[0][0]},${points[0][1]} L ${points[1][0]},${points[1][1]}`;
  }

  let d = `M ${points[0][0]},${points[0][1]}`;

  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[Math.max(i - 1, 0)];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[Math.min(i + 2, points.length - 1)];

    const cp1x = p1[0] + (p2[0] - p0[0]) * tension;
    const cp1y = p1[1] + (p2[1] - p0[1]) * tension;
    const cp2x = p2[0] - (p3[0] - p1[0]) * tension;
    const cp2y = p2[1] - (p3[1] - p1[1]) * tension;

    d += ` C ${cp1x},${cp1y} ${cp2x},${cp2y} ${p2[0]},${p2[1]}`;
  }
  return d;
}

export function Sparkline({
  data,
  accentColor = "var(--lucid-accent)",
  label,
}: SparklineProps) {
  const width = 100;
  const height = 100;
  const padding = 4;

  const { linePath, fillPath, lastPoint, hasMultiplePoints } = useMemo(() => {
    if (data.length === 0) {
      return {
        linePath: "",
        fillPath: "",
        lastPoint: null,
        hasMultiplePoints: false,
      };
    }

    const max = Math.max(...data, 1);
    const min = Math.min(...data, 0);
    const range = max - min || 1;

    const pts: [number, number][] = data.map((value, index) => {
      const x =
        data.length === 1 ? width / 2 : (index / (data.length - 1)) * width;
      const y =
        height - ((value - min) / range) * (height - padding * 2) - padding;
      return [x, Math.max(padding, Math.min(height - padding, y))];
    });

    const line = catmullRomPath(pts);
    const lastPt = pts[pts.length - 1];
    const fill = line
      ? `${line} L ${lastPt[0]},${height} L ${pts[0][0]},${height} Z`
      : "";

    return {
      linePath: line,
      fillPath: fill,
      lastPoint: lastPt,
      hasMultiplePoints: pts.length > 1,
    };
  }, [data]);

  const gradientId = `lucid-sparkline-${label?.replace(/\s/g, "-") || "default"}`;

  if (!linePath) return null;

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      preserveAspectRatio="none"
      className="w-full h-full"
      role="img"
      aria-label={`${label || "Metric"} sparkline chart`}
      style={{ filter: "drop-shadow(0 2px 8px rgba(0, 0, 0, 0.3))" }}
    >
      <defs>
        <linearGradient id={gradientId} x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor={accentColor} stopOpacity="0.4" />
          <stop offset="50%" stopColor={accentColor} stopOpacity="0.2" />
          <stop offset="100%" stopColor={accentColor} stopOpacity="0.05" />
        </linearGradient>

        {/* Glow filter for the line */}
        <filter id={`${gradientId}-glow`}>
          <feGaussianBlur stdDeviation="2" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      {/* Gradient fill area */}
      <path d={fillPath} fill={`url(#${gradientId})`} />

      {/* Glow line (underneath) */}
      <path
        d={linePath}
        fill="none"
        stroke={accentColor}
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
        vectorEffect="non-scaling-stroke"
        opacity="0.4"
        filter={`url(#${gradientId}-glow)`}
      />

      {/* Main line */}
      <path
        d={linePath}
        fill="none"
        stroke={accentColor}
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        vectorEffect="non-scaling-stroke"
      />

      {/* Latest value glow dot */}
      {lastPoint && hasMultiplePoints && (
        <>
          {/* Outer glow ring */}
          <circle
            cx={lastPoint[0]}
            cy={lastPoint[1]}
            r="6"
            fill={accentColor}
            opacity="0.15"
            style={{ animation: "lucid-dot-pulse 2s ease-in-out infinite" }}
          />
          {/* Middle ring */}
          <circle
            cx={lastPoint[0]}
            cy={lastPoint[1]}
            r="4"
            fill={accentColor}
            opacity="0.4"
          />
          {/* Inner dot */}
          <circle
            cx={lastPoint[0]}
            cy={lastPoint[1]}
            r="2.5"
            fill={accentColor}
          />
          {/* Center highlight */}
          <circle
            cx={lastPoint[0]}
            cy={lastPoint[1]}
            r="1"
            fill="white"
            opacity="0.9"
          />
        </>
      )}
    </svg>
  );
}
