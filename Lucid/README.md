# Lucid - Native SwiftUI macOS Activity Monitor

A native SwiftUI macOS application to monitor system processes with Liquid Glass design (macOS 14+).

## Project Structure

```
Lucid/
├── Lucid/
│   ├── LucidApp.swift                    # @main entry point
│   ├── ContentView.swift                 # NavigationSplitView + detail view
│   ├── Info.plist                        # App configuration
│   ├── Lucid.entitlements                # Sandbox disabled for process access
│   ├── BridgingHeader.h                  # C header for libproc.h
│   │
│   ├── Models/
│   │   ├── LucidProcess.swift            # Process struct
│   │   ├── Safety.swift                  # Enum: system/user/unknown
│   │   └── SystemStats.swift             # System metrics
│   │
│   ├── Services/
│   │   ├── ProcessMonitor.swift          # @Observable state manager
│   │   ├── DarwinProcess.swift           # C interop for libproc
│   │   └── ProcessDictionary.swift       # 250+ process lookup table
│   │
│   ├── Views/
│   │   ├── Sidebar/
│   │   │   ├── SidebarView.swift
│   │   │   └── FilterButton.swift
│   │   ├── Content/
│   │   │   └── HeaderBar.swift
│   │   ├── Dashboard/
│   │   │   ├── MetricsRowView.swift
│   │   │   ├── MetricCardView.swift
│   │   │   └── BarSparkline.swift
│   │   └── Shared/
│   │       └── SafetyDot.swift
│   │
│   └── Theme/
│       ├── LucidTheme.swift              # Color tokens, design system
│       └── GlassModifiers.swift          # Liquid Glass effects
```

## Setup Instructions

### Prerequisites
- macOS 14 or later (14+ for full functionality, 26+ for Liquid Glass effects)
- Xcode 15+

### Creating the Xcode Project

All Swift source files have been created. To complete the Xcode project setup:

1. **Open Xcode**
2. **Create a new macOS App project**:
   - File → New → Project
   - macOS → App
   - Product Name: `Lucid`
   - Organization Identifier: `com.tan`
   - Bundle Identifier: `com.tan.lucid`
   - Language: Swift
   - SwiftUI: Yes
   - Core Data: No
   - Create in: This `Lucid` directory

3. **Copy source files**:
   - Copy all `.swift` files from this directory into the Xcode project's source folder
   - Copy `BridgingHeader.h`, `Info.plist`, and `Lucid.entitlements` into the project

4. **Configure Project Settings**:
   - Select the project in Xcode
   - General → Minimum Deployments: macOS 14
   - Build Settings → Search "Bridging Header"
   - Set Bridging Header to: `Lucid/BridgingHeader.h`
   - Signing & Capabilities → Capabilities → Remove "App Sandbox" (Sandboxing must be disabled for process enumeration)

5. **Add Framework**:
   - General → Frameworks and Libraries
   - Add `Charts` (SwiftUI Charts framework)

6. **Build & Run**:
   ```
   Cmd + R
   ```

## Features

- **Real-time Process Monitoring**: Lists all running processes with CPU, memory, and safety classification
- **Safety Classification**: System (green), User (yellow), Unknown (red)
- **Interactive Filtering**: Filter by process category
- **Search**: Search by process name or description
- **Process Control**: Kill processes with confirmation dialog
- **System Metrics**: Real-time CPU, memory, and process count with sparkline charts
- **Liquid Glass Design**: Modern glass-morphism effects (macOS 14+)

## Architecture

### State Management
- `ProcessMonitor` (@Observable): Single source of truth for process data and system stats
- Timer-based polling every 2 seconds
- Delta CPU calculation with multi-core support

### Process Backend
- `DarwinProcess`: C interop using libproc.h
  - `proc_listallpids()`: Enumerate all PIDs
  - `proc_pidinfo()`: Get CPU time (nanoseconds) + memory
  - `proc_name()`: Get process name
  - `kill()`: Terminate process with SIGTERM

### Process Dictionary
- 250+ known macOS processes with descriptions and safety classifications
- Static Swift dictionary with comprehensive process mappings

## Known Limitations

- Processes running as root show zero metrics (privileged access restrictions)
- proc_name is limited to 16 characters (fallback to full path)
- Not App Store distributable (sandbox disabled)
- Multi-core processes can exceed 100% CPU per core

## Next Steps

1. Create the Xcode project using the instructions above
2. Build and run: `Cmd + R`
3. Verify process enumeration works by checking process count matches Activity Monitor
4. Test filtering, search, and process killing
5. Visual verification of Liquid Glass effects on macOS 14+
