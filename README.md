<!-- prettier-ignore -->
<div align="center">

<img src="Resources/icon.svg" alt="Lucid" height="80" />

<h1>Lucid</h1>

<p>A plain-English activity monitor for macOS built with native SwiftUI.</p>

<p>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-FA7343?style=flat-square&logo=swift&logoColor=white" alt="Swift"></a>
  <a href="https://www.apple.com/macos"><img src="https://img.shields.io/badge/macOS-14+-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS"></a>
  <a href="https://github.com/tanRdev/lucid-task-manager/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/tanRdev/lucid-task-manager/ci.yml?branch=main&style=flat-square&label=CI" alt="CI"></a>
  <a href="https://github.com/tanRdev/lucid-task-manager/releases"><img src="https://img.shields.io/github/v/release/tanRdev/lucid-task-manager?style=flat-square" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square" alt="License"></a>
</p>

<p><a href="#quick-start">Quick Start</a> · <a href="#installation">Installation</a> · <a href="#usage">Usage</a> · <a href="#architecture">Architecture</a> · <a href="#development">Development</a> · <a href="#resources">Resources</a></p>

<img src="Resources/app-screenshot.png" alt="Lucid Screenshot" />

</div>

> [!TIP]
> From the repo root, run `cd Lucid && make run` to build Lucid.app and launch it locally on macOS.

## Overview

**Lucid** turns cryptic process names like `mds_stores`, `configd`, and `distnoted` into plain-English descriptions so you can quickly understand what is running on your Mac, how much CPU or memory it is using, and where it likely came from.

## Quick Start

```bash
git clone https://github.com/tanRdev/lucid-task-manager.git
cd lucid-task-manager/Lucid
make run
```

This builds `Lucid.app` from source and opens it locally.

## Installation

### Requirements

- macOS 14 or newer
- Swift 6.0+ toolchain (`swift-tools-version: 6.0`)
- **Full Xcode** (not Command Line Tools alone) to run `make test` / `swift test` — XCTest ships with Xcode

### Build From Source

```bash
git clone https://github.com/tanRdev/lucid-task-manager.git
cd lucid-task-manager/Lucid
make app
```

The generated app bundle is placed in the Swift build output directory and ad-hoc signed (`codesign --verify --deep --strict` must pass).

### Launch During Development

```bash
cd Lucid
make run
```

### Install To `/Applications`

```bash
cd Lucid
make install
```

Or open `Lucid/Package.swift` in Xcode and run the app there.

### Create a DMG

```bash
cd Lucid
make dmg VERSION=1.1.0
```

Set `CODESIGN_IDENTITY` to a Developer ID Application identity for distribution signing. Optionally set `NOTARYTOOL_PROFILE` to notarize with `notarytool`.

> [!NOTE]
> Lucid disables App Sandbox so it can inspect running processes. Development builds work locally; distributing the app outside development requires Developer ID signing and notarization.

### First Launch (developer troubleshooting)

If Gatekeeper blocks an unsigned or ad-hoc build:

1. **Right-click** Lucid.app in Finder → **Open** → **Open** again, or
2. Remove quarantine in Terminal (developer machines only):

```bash
xattr -d com.apple.quarantine /Applications/Lucid.app
```

Prefer Developer ID–signed and notarized builds for end users.

## Usage

1. Launch Lucid.
2. Browse live processes; sort by name, origin, description, CPU, memory, PID, or ports.
3. Search from the toolbar (`⌘F`).
4. Filter by origin or listening port from the sidebar.
5. Inspect a process in the inspector for path, ports, and actions.
6. Terminate only unprotected processes (system-origin processes are blocked).

### Origin Indicators

| Origin | Meaning |
| --- | --- |
| System | Likely macOS / Apple system software. Protected from termination by default. |
| User | Likely user-installed or user-owned apps and tools. |
| Unknown | Classification evidence was weak — treat carefully. |

Origin is a heuristic ownership signal, not a guarantee that quitting a process is safe for your work.

## Features

| Feature | Description |
| --- | --- |
| Plain-English process names | Maps hundreds of common macOS processes to human-readable descriptions |
| Real-time monitoring | Tracks per-process CPU (Activity Monitor–style) and host memory used |
| Port visibility | Shows listening ports in the sidebar, table, and inspector |
| Safer process termination | Confirms destructive actions; blocks system-origin processes; verifies PID + start time |
| Native macOS interface | `NavigationSplitView`, toolbar search, and process inspector |
| Zero third-party dependencies | Uses Swift Package Manager with Apple frameworks only |

## Architecture

```text
Lucid/
├── LucidApp.swift                 # App entry point and lifecycle
├── ContentView.swift              # Navigation split, table, inspector
├── Models/
│   ├── LucidProcess.swift         # Process model + ProcessIdentity
│   ├── ProcessOrigin.swift        # Origin classification (not termination policy alone)
│   └── SystemStats.swift          # Host CPU/memory summary
├── Services/
│   ├── ProcessMonitor.swift       # @MainActor UI state + ProcessSampler actor
│   ├── DarwinProcess.swift        # Darwin process API interop
│   ├── ProcessDictionary.swift    # Human-readable process name mapping
│   └── PortScanner.swift          # Actor-isolated `lsof` port detection
├── Views/
│   ├── Content/                   # Table, settings, inspector chrome
│   ├── Shared/                    # Origin indicators
│   └── Sidebar/                   # Filters, ports, status
└── Theme/
    └── LucidTheme.swift           # Colors and spacing
```

## How It Works

1. `proc_listallpids()` enumerates running processes.
2. `proc_pidinfo()` collects CPU time, resident memory, start time, and uid.
3. `proc_name()` / `proc_pidpath()` identify executables.
4. Host `vm_statistics64` provides Memory Used (active + wired + compressed).
5. `NSWorkspace.shared.runningApplications` fills in GUI app names.
6. `lsof -iTCP -sTCP:LISTEN -n -P` maps listening ports to PIDs.

`ProcessMonitor` publishes UI state on the main actor. Sampling runs in a dedicated `ProcessSampler` actor and uses real monotonic intervals between samples for CPU deltas.

> [!WARNING]
> Some root-owned processes expose limited metrics without elevated privileges, so they may appear with partial CPU or memory information.

## Development

```bash
cd Lucid
# Requires full Xcode selected via xcode-select
make test
make app
make run
```

CI (`.github/workflows/ci.yml`) on `macos-26` runs:

- `swift test`
- `swift build -Xswiftc -warn-concurrency --target Lucid`
- `swift build --configuration release --target Lucid`
- `./build-app.sh debug` plus strict `codesign` verification

## Contributing

Contributions are welcome. Lucid is open source under the [MIT License](LICENSE).

### Ways to Contribute

- **Report bugs** — [Open an issue](https://github.com/tanRdev/lucid-task-manager/issues) with steps to reproduce
- **Suggest features** — Describe the problem you're solving before proposing solutions
- **Improve process mappings** — Add or refine human-readable descriptions in `ProcessDictionary.swift`
- **Submit pull requests** — Fork the repo, branch off `main`, and open a PR with a clear description

### Development Setup

```bash
git clone https://github.com/tanRdev/lucid-task-manager.git
cd lucid-task-manager/Lucid
# Install Xcode, then:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
make test
```

### Code Standards

- Follow existing Swift conventions and formatting
- Add tests for new functionality
- Keep commits focused and descriptive
- Run `make test` before opening a PR (requires Xcode)

## Resources

- [Releases](https://github.com/tanRdev/lucid-task-manager/releases)
- [CI Workflow](.github/workflows/ci.yml)
- [Swift Package Manifest](Lucid/Package.swift)

## License

Lucid is licensed under the MIT License. See the [`LICENSE`](LICENSE) file for details.

## Getting Help

- [Open an issue](https://github.com/tanRdev/lucid-task-manager/issues)
