# Lucid

A plain-English activity monitor for macOS built with native SwiftUI. Lucid translates cryptic process names like `mds_stores`, `configd`, and `distnoted` into human-readable descriptions — "Spotlight Search Indexer", "Configuration Daemon", "Distributed Notification Service" — so you actually know what's running on your machine.

## Features

- **Plain-English descriptions** — Built-in dictionary maps 250+ macOS processes to readable names
- **Safety categories** — Every process is tagged as System (safe, don't touch), User (your apps, safe to kill), or Unknown, with color-coded indicators
- **Real-time monitoring** — CPU and memory usage updated every 2 seconds with smooth sparkline charts
- **Kill with confidence** — Terminate processes directly from the UI, with a confirmation dialog and system-process protection
- **Native performance** — SwiftUI Table with built-in virtualization handles thousands of processes
- **Liquid Glass design** — Modern iOS 26+ glass effects with graceful fallbacks for older macOS versions
- **Pure Swift** — No dependencies, just Apple frameworks (SwiftUI, Charts, Darwin)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI (macOS 14+) |
| Design System | Liquid Glass (macOS 26+) with Material fallbacks |
| Charts | Swift Charts |
| Process Monitoring | Darwin C APIs (`libproc.h`, `sysctl`) |
| State Management | `@Observable` + `@Environment` |
| Language | Swift 5.9+ |

## Prerequisites

- **Xcode 15+** — Required for SwiftUI and Swift 5.9 features
- **macOS Sonoma 14.0+** — Deployment target for `@Observable` macro
- **macOS Sequoia 26.0+** — Optional, for Liquid Glass effects

## Getting Started

1. Open `Lucid/Lucid.xcodeproj` in Xcode
2. Build and run (⌘R)

The app does not use App Sandbox to access process information. For development, code signing is automatic. For distribution, use a Developer ID certificate.

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

## How It Works

1. **Process enumeration** — Uses Darwin C APIs (`proc_listallpids`, `proc_pidinfo`) to enumerate all running processes
2. **Process dictionary** — A static Swift dictionary maps 250+ process names to human-readable descriptions and safety categories
3. **CPU calculation** — Delta-based CPU percentage using `pti_total_user` and `pti_total_system` nanoseconds between samples
4. **Hybrid naming** — Combines `NSWorkspace.runningApplications` (for full GUI app names) with `proc_name` (for daemons)
5. **SwiftUI Table** — Native macOS multi-column table with sorting, selection, and built-in virtualization
6. **Timer polling** — `ProcessMonitor` uses a `Timer` that fires every 2 seconds on the main thread
7. **Liquid Glass** — `#available(macOS 26, *)` guards apply glass effects on compatible systems, fallback to dark cards on older versions

## Process Monitoring Details

### Darwin C APIs Used

- `proc_listallpids()` — Get all process IDs
- `proc_pidinfo(pid, PROC_PIDTASKINFO)` — Get CPU time (nanoseconds) and resident memory
- `proc_name(pid)` — Get process name (max 16 chars)
- `proc_pidpath(pid)` — Get executable path
- `NSWorkspace.shared.runningApplications` — Get full GUI app names (workaround for truncation)
- `kill(pid, SIGTERM)` — Terminate process

### Limitations

- **Root processes** — Cannot read task info for root-owned processes without elevated privileges. These processes appear with 0 CPU/memory.
- **App Sandbox** — The app disables the sandbox for full process visibility. Not distributable via Mac App Store.
- **Name truncation** — `proc_name` is limited to 16 characters. GUI apps use `NSWorkspace` for full names.

## Building & Distribution

### Development
1. Open in Xcode
2. Build and run (⌘R)
3. Code signing is automatic for development

### Distribution
1. Build for release (Product → Archive)
2. Export with Developer ID certificate
3. Notarize with Apple
4. Distribute as DMG or ZIP

**Note:** Cannot distribute via Mac App Store due to sandbox restrictions on `proc_listallpids`.

## License

MIT
