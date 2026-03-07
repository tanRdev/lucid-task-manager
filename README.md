# <img src="Resources/app-icon.png" alt="Lucid" height="32" style="vertical-align: middle; margin-right: 6px;"> Lucid

A plain-English activity monitor for macOS built with native SwiftUI. Lucid translates cryptic process names like `mds_stores`, `configd`, and `distnoted` into human-readable descriptions — "Spotlight Search Indexer", "Configuration Daemon", "Distributed Notification Service" — so you can see what's running on your machine.

![Lucid Screenshot](Resources/app-screenshot.png)

## Features

- **Plain-English descriptions** — 250+ macOS processes mapped to readable names and explanations
- **Safety categories** — Each process tagged System (protected), User (your apps), or Unknown, with color-coded indicators
- **Real-time monitoring** — CPU and memory usage updated every 2 seconds with sparkline charts
- **Process termination** — Kill processes from the UI with confirmation dialogs and protection for system processes
- **Native performance** — SwiftUI Table with virtualization handles thousands of processes efficiently
- **Liquid Glass design** — macOS 26 Tahoe glass effects on compatible systems, with Material fallbacks for older versions
- **Pure Swift** — No dependencies, only Apple frameworks (SwiftUI, Charts, Darwin)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI (macOS 14+) |
| Design System | Liquid Glass (macOS 26) with Material fallbacks |
| Charts | Swift Charts |
| Process Monitoring | Darwin C APIs (`libproc.h`, `sysctl`) |
| State Management | `@Observable` + `@Environment` |
| Language | Swift 5.9+ |

## Prerequisites

- **Xcode 15+** — Required for SwiftUI and Swift 5.9 features
- **macOS Sonoma 14.0+** — Deployment target for `@Observable` macro
- **macOS Tahoe 26.0+** — Optional, for Liquid Glass effects

## Getting Started

### Xcode

1. Open `Lucid/Package.swift` in Xcode
2. Build and run (⌘R)

### Command line (macOS)

```bash
cd Lucid
make app      # builds executable + Lucid.app bundle
make run      # builds and launches Lucid.app
make test     # runs unit tests
```

Lucid disables App Sandbox to access process information. Development builds sign automatically; distribution requires a Developer ID certificate.

## Architecture

```
Lucid/
├── LucidApp.swift                     # @main, WindowGroup, environment injection
├── ContentView.swift                  # NavigationSplitView (sidebar + detail)
│
├── Models/
│   ├── LucidProcess.swift             # Process data model
│   ├── Safety.swift                   # Safety enum (system/user/unknown)
│   └── SystemStats.swift              # Aggregated metrics + history
│
├── Services/
│   ├── ProcessMonitor.swift           # @Observable: Timer polling, refresh, kill
│   ├── DarwinProcess.swift            # C interop: proc_listallpids, proc_pidinfo
│   └── ProcessDictionary.swift        # Static dictionary: 250+ process mappings
│
├── Views/
│   ├── Sidebar/                       # Filter buttons + system overview
│   ├── Content/                       # Table + header + kill confirmation
│   ├── Dashboard/                     # Metric cards + sparklines
│   └── Shared/                        # Reusable components
│
└── Theme/
    ├── LucidTheme.swift               # Color tokens, fonts
    └── GlassModifiers.swift           # Liquid Glass helpers with #available guards
```

**Key architectural patterns:**
- **State Management**: `@Observable` ProcessMonitor as single source of truth, injected via `@Environment`
- **Timer Loop**: ProcessMonitor polls every 2 seconds, coordinating all services
- **Data Flow**: Darwin APIs → ProcessMonitor → @Observable state → SwiftUI views
- **Service Integration**: PortScanner (lsof), LLMService (actor), ProcessDictionary (250+ mappings)

## How It Works

Lucid uses Darwin C APIs for process enumeration and monitoring:

- `proc_listallpids()` — Enumerate all running processes
- `proc_pidinfo(pid, PROC_PIDTASKINFO)` — Get CPU time (nanoseconds) and resident memory
- `proc_name(pid)` — Get process name (max 16 chars)
- `proc_pidpath(pid)` — Get executable path
- `NSWorkspace.shared.runningApplications` — Get full GUI app names (workaround for truncation)

CPU percentage is computed from nanosecond deltas in `pti_total_user` and `pti_total_system` between samples. A static dictionary maps 250+ process names to human-readable descriptions and safety categories.

**Limitations:**
- Root processes appear with 0 CPU/memory without elevated privileges
- App Sandbox is disabled for process visibility (not Mac App Store compatible)
- `proc_name` truncates at 16 characters; GUI apps use `NSWorkspace` for full names

## Building & Distribution

Distribution builds require a Developer ID certificate and Apple notarization.

## Continuous Integration

GitHub Actions runs on macOS for each push and pull request:

1. `swift test`
2. `./build-app.sh debug`

Workflow file: `.github/workflows/ci.yml`.

## License

MIT
