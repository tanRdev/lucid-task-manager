# Lucid

A plain-English activity monitor for macOS. Lucid translates cryptic process names like `mds_stores`, `configd`, and `distnoted` into human-readable descriptions — "Spotlight Search Indexer", "Configuration Daemon", "Distributed Notification Service" — so you actually know what's running on your machine.

## Features

- **Plain-English descriptions** — Built-in dictionary maps 100+ macOS processes to readable names
- **Safety categories** — Every process is tagged as System (safe, don't touch), User (your apps, safe to kill), or Unknown, with color-coded indicators
- **Real-time monitoring** — CPU and memory usage updated every 2 seconds with smooth sparkline charts
- **Kill with confidence** — Terminate processes directly from the UI, with a confirmation dialog and system-process protection
- **Fast** — Virtualized table renders thousands of processes without breaking a sweat
- **Native macOS feel** — Frosted glass vibrancy, translucent surfaces, and a compact sidebar that feels at home on macOS

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Desktop framework | [Tauri v2](https://v2.tauri.app/) |
| Backend | Rust + [sysinfo](https://crates.io/crates/sysinfo) |
| Frontend | React 19, TypeScript, [Tailwind CSS v4](https://tailwindcss.com/) |
| UI components | [shadcn/ui](https://ui.shadcn.com/) + [Radix](https://www.radix-ui.com/) |
| Type-safe effects | [Effect-TS](https://effect.website/) for typed errors and schema validation |
| Virtualization | [@tanstack/react-virtual](https://tanstack.com/virtual) |
| Vibrancy | [window-vibrancy](https://crates.io/crates/window-vibrancy) (NSVisualEffectView) |
| Linting | [Biome](https://biomejs.dev/) |

## Prerequisites

- **Rust** — Install via [rustup](https://rustup.rs/)
- **Node.js 18+** — Install via [nvm](https://github.com/nvm-sh/nvm) or [nodejs.org](https://nodejs.org/)
- **macOS** — Required for native vibrancy (the app builds on other platforms but vibrancy is macOS-only)

## Getting Started

```bash
# Clone the repo
git clone https://github.com/your-username/lucid.git
cd lucid

# Install frontend dependencies
npm install

# Run in development mode (launches both Vite dev server and Tauri window)
npm run tauri dev
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run tauri dev` | Start the app in development mode |
| `npm run tauri build` | Build a production `.app` bundle |
| `npm run dev` | Start the Vite dev server only (no Tauri) |
| `npm run build` | Build the frontend only |
| `npm run lint` | Check for lint errors with Biome |
| `npm run lint:fix` | Auto-fix lint errors |
| `npm run format` | Format source files with Biome |

## Architecture

```
src/                          # React frontend
├── App.tsx                   # Root layout (titlebar, sidebar, content)
├── components/
│   ├── Sidebar.tsx           # Navigation sidebar with status indicator
│   ├── SystemLoadCard.tsx    # CPU/Memory gauges with sparkline charts
│   ├── ProcessTableNew.tsx   # Virtualized process table with search/sort/kill
│   ├── Sparkline.tsx         # SVG sparkline with Catmull-Rom smooth curves
│   ├── SafetyDot.tsx         # Color-coded safety indicator with tooltip
│   └── ui/                   # shadcn/ui primitives
├── hooks/
│   └── useProcesses.ts       # Effect-TS fiber that polls Rust backend
├── services/
│   ├── commands.ts           # Typed Tauri IPC commands via Effect
│   ├── errors.ts             # Typed error classes (InvokeError, DecodeError, etc.)
│   └── schemas.ts            # Effect Schema for process data validation
├── lib/
│   ├── runtime.ts            # Effect runtime instance
│   └── utils.ts              # Tailwind merge utility
├── types.ts                  # Shared TypeScript types
└── index.css                 # Lucid design system (tokens, glass, typography)

src-tauri/                    # Rust backend
├── src/
│   ├── lib.rs                # Tauri setup, vibrancy config, command registration
│   ├── commands.rs           # Tauri IPC command handlers
│   ├── process.rs            # Process enumeration and kill via sysinfo
│   └── dictionary.rs         # Plain-English process name dictionary
└── tauri.conf.json           # Tauri window and build configuration
```

## How It Works

1. **Rust backend** uses `sysinfo` to enumerate all running processes, collecting PID, name, CPU usage, memory, and executable path
2. **Process dictionary** (`dictionary.rs`) maps known process names to human-readable descriptions and safety categories (System, User, Unknown)
3. **Tauri IPC** exposes `get_processes` and `kill_process` commands to the frontend
4. **Effect-TS** wraps IPC calls with typed errors (`InvokeError`, `DecodeError`, `KillDeniedError`) and validates response data against schemas
5. **React frontend** polls the backend every 2 seconds via an Effect fiber, rendering a virtualized table and real-time sparkline charts

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes and ensure `npm run lint` passes
4. Commit with a clear message
5. Open a pull request

## License

MIT
