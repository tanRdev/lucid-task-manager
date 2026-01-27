import Foundation
import AppKit

struct ProcessDictionary {
    private static let dictionary: [String: (String, Safety)] = [
        // Core macOS System Processes (Green - System)
        "kernel_task": ("macOS Kernel", .system),
        "launchd": ("System Launch Daemon", .system),
        "SystemUIServer": ("System UI Server", .system),
        "WindowServer": ("Window Manager", .system),
        "Dock": ("macOS Dock", .system),
        "Finder": ("macOS Finder", .system),
        "loginwindow": ("Login Window Manager", .system),
        "UserEventAgent": ("User Event Agent", .system),
        "mds": ("Spotlight Metadata Server", .system),
        "mds_stores": ("Spotlight Search Indexer", .system),
        "mdworker": ("Spotlight Worker", .system),
        "mdworker_shared": ("Spotlight Shared Worker", .system),
        "mdflagwriter": ("Spotlight Flag Writer", .system),
        "mdutil": ("Spotlight Utility", .system),
        "hidd": ("Human Interface Device Daemon", .system),
        "coreaudiod": ("Core Audio Daemon", .system),
        "bluetoothd": ("Bluetooth Daemon", .system),
        "blued": ("Bluetooth Server", .system),
        "airportd": ("WiFi Manager", .system),
        "notifyd": ("Notification Server", .system),
        "syslogd": ("System Logging Daemon", .system),
        "apsd": ("Apple Push Notification Service", .system),
        "securityd": ("Security Framework Daemon", .system),
        "opendirectoryd": ("Directory Services", .system),
        "configd": ("Configuration Daemon", .system),
        "networkd": ("Network Management Daemon", .system),
        "distnoted": ("Distributed Notification Service", .system),
        "coreservicesd": ("Core Services Daemon", .system),
        "CoreServicesUIAgent": ("Core Services UI Agent", .system),
        "fontd": ("Font Management Daemon", .system),
        "cfprefsd": ("Preferences Daemon", .system),
        "discoveryd": ("Network Discovery Daemon", .system),
        "nsurlsessiond": ("URL Session Daemon", .system),
        "nsurlstoraged": ("URL Storage Daemon", .system),
        "powerd": ("Power Management Daemon", .system),
        "thermald": ("Thermal Management", .system),
        "kernelmanagerd": ("Kernel Extension Manager", .system),
        "kextd": ("Kernel Extension Daemon", .system),
        "fseventsd": ("File System Events Daemon", .system),
        "revisiond": ("iCloud Versions Daemon", .system),
        "bird": ("iCloud Sync Daemon", .system),
        "cloudd": ("iCloud Daemon", .system),
        "cloudpaird": ("iCloud Device Pairing", .system),
        "AppleSpell": ("Spell Check Service", .system),
        "AirPlayUIAgent": ("AirPlay UI Agent", .system),
        "AirPlayXPCHelper": ("AirPlay Helper", .system),
        "accountsd": ("Accounts Framework", .system),
        "CalendarAgent": ("Calendar Background Agent", .system),
        "ContactsAgent": ("Contacts Background Agent", .system),
        "notificationcenterui": ("Notification Center UI", .system),
        "ControlCenter": ("Control Center", .system),
        "Control Center": ("Control Center", .system),
        "talagent": ("Time and Location Agent", .system),
        "LaterAgent": ("Notification Scheduling Agent", .system),
        "AppSSOAgent": ("App Single Sign-On Agent", .system),
        "CommCenter": ("Communication Center", .system),
        "corecaptured": ("Core Capture Daemon", .system),
        "ScopedBookmarkAgent": ("Bookmark Scope Agent", .system),
        "ViewBridgeAuxiliary": ("View Bridge Service", .system),
        "WiFiAgent": ("WiFi Agent", .system),
        "sharingd": ("Sharing Services Daemon", .system),
        "rapportd": ("Continuity Daemon", .system),
        "imagent": ("iMessage Agent", .system),
        "SafariBookmarksSyncAgent": ("Safari Bookmarks Sync", .system),
        "findmydeviced": ("Find My Device Daemon", .system),
        "softwareupdated": ("Software Update Daemon", .system),
        "storedownloadd": ("App Store Download Manager", .system),
        "trustd": ("Certificate Trust Daemon", .system),
        "gamecontrollerd": ("Game Controller Daemon", .system),
        "displaypolicyd": ("Display Policy Daemon", .system),
        "displayservicesd": ("Display Services Daemon", .system),
        "secinitd": ("Security Initialization", .system),
        "secd": ("Security Daemon", .system),
        "authd": ("Authorization Daemon", .system),
        "lsd": ("Launch Services Daemon", .system),
        "iconservicesd": ("Icon Services Daemon", .system),
        "iconservicesagent": ("Icon Services Agent", .system),
        "symptomsd": ("Network Symptoms Daemon", .system),
        "networkserviceproxy": ("Network Service Proxy", .system),
        "socketfilterfw": ("Application Firewall", .system),
        "tccd": ("Privacy Preferences Daemon", .system),
        "locationd": ("Location Services Daemon", .system),
        "warmd": ("System Warmup Daemon", .system),
        "watchdogd": ("Watchdog Daemon", .system),
        "keybagd": ("Keychain Keybag Daemon", .system),
        "deleted": ("Deleted Process Cache", .system),
        "amfird": ("App Management Framework", .system),
        "appstoreagent": ("App Store Agent", .system),
        "AssetCacheLocatorService": ("Content Cache Locator", .system),
        "biometrickitd": ("Touch ID & Face ID Manager", .system),
        "calaccessd": ("Calendar Access Daemon", .system),
        "CategoriesService": ("Content Categories Service", .system),
        "cloudphotod": ("iCloud Photos Daemon", .system),
        "colorsync.displayservices": ("ColorSync Display Services", .system),
        "ContextStoreAgent": ("Context Store Agent", .system),
        "coreduetd": ("Core Duet Daemon", .system),
        "corekdld": ("Core Kernel Debug Link", .system),
        "corespeechd": ("Core Speech Daemon", .system),
        "CoreLocationAgent": ("Location Agent", .system),
        "CrashReporterSupportHelper": ("Crash Reporter Helper", .system),
        "familycircled": ("Family Sharing Daemon", .system),
        "fileproviderd": ("File Provider Daemon", .system),
        "FindMyFriend": ("Find My Friends Service", .system),
        "FMCore": ("Find My Core Service", .system),
        "identityservicesd": ("Identity Services Daemon", .system),
        "IMAutomaticHistoryDeletionAgent": ("Message History Cleaner", .system),
        "IMDPersistenceAgent": ("Message Persistence Agent", .system),
        "IMRemoteURLConnectionAgent": ("Message URL Agent", .system),
        "kbd": ("Keyboard Services", .system),
        "keyboardservicesd": ("Keyboard Services Daemon", .system),
        "languageassetd": ("Language Asset Daemon", .system),
        "mediaremoted": ("Media Remote Daemon", .system),
        "mediaserverd": ("Media Server Daemon", .system),
        "nearbyd": ("Nearby Interaction Daemon", .system),
        "netbiosd": ("NetBIOS Daemon", .system),
        "nfcd": ("NFC Daemon", .system),
        "parentalcontrolsd": ("Parental Controls", .system),
        "parsecd": ("Parsing Daemon", .system),
        "pbs": ("Pasteboard Server", .system),
        "pkd": ("Extension Manager", .system),
        "ProtectedCloudKeySyncing": ("iCloud Key Sync", .system),
        "quicklookd": ("Quick Look Daemon", .system),
        "QuickLookUIService": ("Quick Look UI Service", .system),
        "replayd": ("Screen Recording Service", .system),
        "sandboxd": ("Sandbox Daemon", .system),
        "searchpartyd": ("Spotlight Party Daemon", .system),
        "storeassetd": ("App Store Asset Manager", .system),
        "swcd": ("Software Update Control", .system),
        "SubmitDiagInfo": ("Diagnostic Submission", .system),
        "syncdefaultsd": ("Sync Defaults Daemon", .system),
        "sysmond": ("System Monitor Daemon", .system),
        "universalaccessd": ("Accessibility Daemon", .system),
        "universalaccessAuthWarn": ("Accessibility Warning", .system),
        "usbd": ("USB Daemon", .system),
        "useractivityd": ("User Activity Daemon", .system),
        "videosubscriptionsd": ("Video Subscriptions Service", .system),
        "wifip2pd": ("WiFi Peer-to-Peer", .system),
        "XprotectService": ("Malware Protection Service", .system),

        // Shell & Command Line (System)
        "zsh": ("Z Shell (Command Line)", .system),
        "bash": ("Bash Shell (Command Line)", .system),
        "sh": ("Bourne Shell (Command Line)", .system),
        "fish": ("Fish Shell (Command Line)", .system),

        // XProtect Services (Malware Protection)
        "XProtectPlugin": ("Malware Protection Plugin", .system),
        "XProtectPluginService": ("Malware Protection Plugin Service", .system),
        "XProtectRemediatorEngine": ("Malware Remediation Engine", .system),
        "XprotectFrameworkService": ("XProtect Framework Service", .system),

        // WiFi & Networking
        "wifivelocityd": ("WiFi Velocity Daemon", .system),
        "WiFiDiagnosticsAgent": ("WiFi Diagnostics Agent", .system),
        "WiFiProximityAgent": ("WiFi Proximity Agent", .system),
        "WiFiNetworkDiagnostics": ("WiFi Network Diagnostics", .system),
        "WiFiVelocityAgent": ("WiFi Velocity Agent", .system),

        // Weather Services
        "WeatherWidget": ("Weather Widget", .system),
        "weatherd": ("Weather Daemon", .system),
        "WeatherKitHelper": ("WeatherKit Helper", .system),
        "WeatherKitService": ("WeatherKit Service", .system),

        // Wallpaper & Desktop
        "WallpaperAgent": ("Wallpaper Agent", .system),
        "WallpaperService": ("Wallpaper Service", .system),
        "wallpaperd": ("Wallpaper Daemon", .system),
        "WallpaperExtension": ("Wallpaper Extension", .system),

        // Window Server & Graphics
        "WindowManager": ("Window Manager", .system),
        "windowserver": ("Window Server", .system),
        "com.apple.WindowManager": ("Window Manager Service", .system),

        // Siri & Intelligence
        "Siri": ("Siri Voice Assistant", .system),
        "SiriNCService": ("Siri Notification Center Service", .system),
        "assistant_service": ("Assistant Service", .system),
        "assistantd": ("Assistant Daemon", .system),
        "SiriKitService": ("SiriKit Service", .system),

        // Spotlight & Search
        "com.apple.mdworker": ("Spotlight Worker Process", .system),

        // Core Services
        "coresymbolicationd": ("Core Symbolication Daemon", .system),
        "coreTelephonyNotificationAgent": ("Telephony Notification Agent", .system),
        "CoreTimeActivity": ("Core Time Activity", .system),
        "CoreServicesAccountAgent": ("Core Services Account Agent", .system),

        // Privacy & Security
        "PrivacyAgent": ("Privacy Agent", .system),
        "PrivacyService": ("Privacy Service", .system),
        "privacyd": ("Privacy Daemon", .system),

        // Notification & Communications
        "NotificationCenter": ("Notification Center", .system),
        "com.apple.notificationcenterui": ("Notification Center UI", .system),
        "APNSAgent": ("Apple Push Notification Agent", .system),

        // iCloud Services
        "iCloudDrive": ("iCloud Drive", .system),
        "iCloudHelper": ("iCloud Helper", .system),
        "com.apple.iCloudHelper": ("iCloud Helper Service", .system),

        // System Extensions
        "SystemExtensionsHost": ("System Extensions Host", .system),
        "SystemMigrationd": ("System Migration Daemon", .system),
        "SystemPolicyAgent": ("System Policy Agent", .system),

        // Print Services
        "PrinterProxy": ("Printer Proxy", .system),
        "PrintingService": ("Printing Service", .system),
        "cupsd": ("CUPS Print Server", .system),

        // Updates & Maintenance
        "SoftwareUpdateNotificationManager": ("Software Update Notifications", .system),
        "mobileassetd": ("Mobile Asset Daemon", .system),
        "com.apple.MobileAsset": ("Mobile Asset Service", .system),

        // Dictation & Input
        "DictationIM": ("Dictation Input Method", .system),
        "com.apple.speech.synthesisserver": ("Speech Synthesis Server", .system),
        "TextInputSwitcher": ("Text Input Switcher", .system),

        // Continuity & Handoff
        "HandoffAgent": ("Handoff Agent", .system),
        "ContinuityAgent": ("Continuity Agent", .system),
        "com.apple.coreservices.uiagent": ("Core Services UI Agent", .system),

        // Dock & Launchpad
        "com.apple.dock.extras": ("Dock Extras", .system),
        "LaunchpadManager": ("Launchpad Manager", .system),

        // Finder Extensions
        "com.apple.quicklook": ("Quick Look Service", .system),
        "QLPreviewExtension": ("Quick Look Preview Extension", .system),

        // Misc System Services
        "AirDropAgent": ("AirDrop Agent", .system),
        "AirPortBaseStationAgent": ("AirPort Base Station Agent", .system),
        "appleh13camerad": ("Camera Daemon", .system),
        "BiomeAgent": ("Biome Agent", .system),
        "com.apple.Safari.History": ("Safari History Service", .system),
        "com.apple.Safari.SafeBrowsing.Service": ("Safari Safe Browsing", .system),
        "DesktopServicesHelper": ("Desktop Services Helper", .system),
        "diagnostics_agent": ("Diagnostics Agent", .system),
        "dprivacyd": ("Display Privacy Daemon", .system),
        "FamilyCircle": ("Family Circle Agent", .system),
        "Family Sharing": ("Family Sharing Service", .system),
        "FontValidatorService": ("Font Validator Service", .system),
        "GameCenterUIService": ("Game Center UI Service", .system),
        "geod": ("Location Services Daemon", .system),
        "HIDSystemServer": ("Human Interface Device Server", .system),
        "InstallAssistant": ("Install Assistant", .system),
        "IntentsExtension": ("Intents Extension", .system),
        "kernel": ("Kernel Process", .system),
        "KerberosAgent": ("Kerberos Authentication Agent", .system),
        "keyboardmigrator": ("Keyboard Migrator", .system),
        "LocalAuthenticationUIAgent": ("Local Authentication UI", .system),
        "MDCrashReportTool": ("Crash Report Tool", .system),
        "MRTd": ("Malware Removal Tool Daemon", .system),
        "MTLCompilerService": ("Metal Compiler Service", .system),
        "NetworkConfigAgent": ("Network Config Agent", .system),
        "PassbookUIService": ("Passbook UI Service", .system),
        "remoted": ("Remote Daemon", .system),
        "SafariCloudHistoryPushAgent": ("Safari Cloud History Push", .system),
        "screencaptureui": ("Screenshot UI", .system),
        "ScreenTimeAgent": ("Screen Time Agent", .system),
        "Security": ("Security Service", .system),
        "seserviced": ("System Events Service", .system),
        "SocialPushAgent": ("Social Push Agent", .system),
        "SpotlightIndexingAgent": ("Spotlight Indexing Agent", .system),
        "TelephonyUtilities": ("Telephony Utilities", .system),
        "TimeMachine": ("Time Machine", .system),
        "tmhelper": ("Time Machine Helper", .system),
        "TouchBarServer": ("Touch Bar Server", .system),
        "UserAccountAgent": ("User Account Agent", .system),
        "VoiceOver": ("VoiceOver Accessibility", .system),
        "WiFiVelocity": ("WiFi Velocity Service", .system),

        // User Applications (Yellow - User)
        "Safari": ("Safari Web Browser", .user),
        "Google Chrome": ("Chrome Web Browser", .user),
        "Google Chrome Helper": ("Chrome Helper Process", .user),
        "Chrome Helper": ("Chrome Helper Process", .user),
        "Firefox": ("Firefox Web Browser", .user),
        "Arc": ("Arc Web Browser", .user),
        "Brave Browser": ("Brave Web Browser", .user),
        "Mail": ("Mail Application", .user),
        "Messages": ("Messages Application", .user),
        "FaceTime": ("FaceTime Application", .user),
        "Photos": ("Photos Application", .user),
        "Music": ("Music Application", .user),
        "iTunes": ("iTunes Application", .user),
        "TV": ("Apple TV Application", .user),
        "Podcasts": ("Podcasts Application", .user),
        "Books": ("Books Application", .user),
        "Maps": ("Maps Application", .user),
        "Calendar": ("Calendar Application", .user),
        "Contacts": ("Contacts Application", .user),
        "Notes": ("Notes Application", .user),
        "Reminders": ("Reminders Application", .user),
        "Preview": ("Preview Application", .user),
        "TextEdit": ("Text Editor", .user),
        "Terminal": ("Terminal Application", .user),
        "Console": ("Console Application", .user),
        "Activity Monitor": ("Activity Monitor", .user),
        "System Settings": ("System Settings", .user),
        "System Preferences": ("System Preferences", .user),
        "App Store": ("App Store Application", .user),
        "Keynote": ("Keynote Presentation App", .user),
        "Pages": ("Pages Word Processor", .user),
        "Numbers": ("Numbers Spreadsheet App", .user),
        "Xcode": ("Xcode IDE", .user),
        "Microsoft Word": ("Microsoft Word", .user),
        "Microsoft Excel": ("Microsoft Excel", .user),
        "Microsoft PowerPoint": ("Microsoft PowerPoint", .user),
        "Microsoft Outlook": ("Microsoft Outlook", .user),
        "Slack": ("Slack Messaging", .user),
        "Slack Helper": ("Slack Helper Process", .user),
        "Discord": ("Discord Communication", .user),
        "Discord Helper": ("Discord Helper Process", .user),
        "Zoom": ("Zoom Video Conferencing", .user),
        "zoom.us": ("Zoom Video Conferencing", .user),
        "Microsoft Teams": ("Microsoft Teams", .user),
        "Spotify": ("Spotify Music", .user),
        "Spotify Helper": ("Spotify Helper Process", .user),
        "VLC": ("VLC Media Player", .user),
        "IINA": ("IINA Media Player", .user),
        "Telegram": ("Telegram Messaging", .user),
        "WhatsApp": ("WhatsApp Messaging", .user),
        "Notion": ("Notion Workspace", .user),
        "Notion Helper": ("Notion Helper Process", .user),
        "Obsidian": ("Obsidian Notes", .user),
        "Visual Studio Code": ("VS Code Editor", .user),
        "Code Helper": ("VS Code Helper Process", .user),
        "IntelliJ IDEA": ("IntelliJ IDEA IDE", .user),
        "PyCharm": ("PyCharm IDE", .user),
        "Sublime Text": ("Sublime Text Editor", .user),
        "Atom": ("Atom Editor", .user),
        "iTerm2": ("iTerm2 Terminal", .user),
        "Alacritty": ("Alacritty Terminal", .user),
        "Docker": ("Docker Desktop", .user),
        "Docker Desktop": ("Docker Desktop", .user),
        "Postman": ("Postman API Client", .user),
        "Figma": ("Figma Design Tool", .user),
        "Adobe Photoshop": ("Adobe Photoshop", .user),
        "Adobe Illustrator": ("Adobe Illustrator", .user),
        "Adobe Premiere Pro": ("Adobe Premiere Pro", .user),
        "Final Cut Pro": ("Final Cut Pro", .user),
        "1Password": ("1Password Password Manager", .user),
        "Dropbox": ("Dropbox Cloud Storage", .user),
        "Google Drive": ("Google Drive Cloud Storage", .user),
        "OneDrive": ("Microsoft OneDrive", .user),
        "Alfred": ("Alfred Productivity App", .user),
        "Raycast": ("Raycast Launcher", .user),
        "Rectangle": ("Rectangle Window Manager", .user),
        "Magnet": ("Magnet Window Manager", .user),
        "Bartender": ("Bartender Menu Bar Manager", .user),
        "CleanMyMac X": ("CleanMyMac Utility", .user),
        "MonitorControl": ("Monitor Control Utility", .user),
        "The Unarchiver": ("The Unarchiver", .user),
        "Transmission": ("Transmission BitTorrent", .user),
    ]

    static func lookup(_ processName: String) -> (String, Safety)? {
        dictionary[processName]
    }

    static func lookup(_ processName: String, defaultDescription: String = "Unknown") -> (String, Safety) {
        if let entry = dictionary[processName] {
            return entry
        }
        return (defaultDescription, .unknown)
    }

    // MARK: - Smart Lookup (multi-layer identification)

    /// Multi-layer process identification. `nsAppName` should be pre-resolved
    /// from NSWorkspace on the main thread before calling this.
    static func smartLookup(name: String, path: String, nsAppName: String?) -> (String, Safety) {
        // 1. Static dictionary — exact match
        if let entry = dictionary[name] {
            return entry
        }

        // 2. NSWorkspace — identifies GUI applications by PID
        if let appName = nsAppName {
            return (appName, .user)
        }

        // 3. App bundle extraction — derive app name from .app path component
        if let bundleResult = appBundleLookup(name: name, path: path) {
            return bundleResult
        }

        // 4. Path-based categorization
        if let pathResult = pathBasedLookup(name: name, path: path) {
            return pathResult
        }

        // 5. Name pattern heuristics
        if let patternResult = patternBasedLookup(name: name) {
            return patternResult
        }

        // 6. Final fallback — still unknown
        return (name, .unknown)
    }

    // MARK: - Layer 3: App bundle extraction

    private static func appBundleLookup(name: String, path: String) -> (String, Safety)? {
        guard !path.isEmpty else { return nil }

        // Find the outermost .app bundle in the path
        // e.g. /Applications/Slack.app/Contents/Frameworks/Slack Helper.app/Contents/MacOS/Slack Helper
        //   → parent app = "Slack"
        guard let appRange = path.range(of: ".app/", options: .literal) ?? path.range(of: ".app", options: [.literal, .backwards]) else {
            return nil
        }

        let beforeApp = path[path.startIndex..<appRange.lowerBound]
        let appName = String(beforeApp.split(separator: "/").last ?? "")

        guard !appName.isEmpty else { return nil }

        // Determine if this process IS the app or a helper/subprocess of it
        let isHelper = name != appName
        let safety: Safety = path.hasPrefix("/Applications") || path.contains("/Users/") ? .user : .system

        if isHelper {
            return ("\(appName) (\(humanizeProcessRole(name)))", safety)
        } else {
            return (appName, safety)
        }
    }

    // MARK: - Layer 4: Path-based categorization

    private static func pathBasedLookup(name: String, path: String) -> (String, Safety)? {
        guard !path.isEmpty else { return nil }

        // Apple system paths
        let systemPrefixes = [
            "/System/Library/",
            "/usr/libexec/",
            "/usr/sbin/",
            "/usr/bin/",
            "/Library/Apple/",
            "/System/iOSSupport/",
            "/System/Volumes/",
        ]

        for prefix in systemPrefixes {
            if path.hasPrefix(prefix) {
                return (describeSystemPath(name: name, path: path), .system)
            }
        }

        // Apple frameworks in /Library
        if path.hasPrefix("/Library/") && !path.hasPrefix("/Library/Application Support/") {
            return (describeSystemPath(name: name, path: path), .system)
        }

        // User application paths
        if path.hasPrefix("/Applications/") {
            return ("\(name)", .user)
        }

        // User home directory paths
        if path.contains("/Users/") {
            return ("\(name)", .user)
        }

        // Homebrew / developer tools
        if path.hasPrefix("/opt/homebrew/") || path.hasPrefix("/usr/local/") {
            return ("\(name)", .user)
        }

        return nil
    }

    // MARK: - Layer 5: Name pattern heuristics

    private static func patternBasedLookup(name: String) -> (String, Safety)? {
        // com.apple.* prefix — definitely Apple system
        if name.hasPrefix("com.apple.") {
            let shortName = String(name.dropFirst("com.apple.".count))
            return ("Apple \(humanizeDotNotation(shortName))", .system)
        }

        // Common daemon suffix pattern: name ends in 'd' and is lowercase
        // (e.g. "bluetoothd", "networkd") — but not short words like "pod"
        if name.count > 3,
           name.last == "d",
           name == name.lowercased(),
           !name.contains(" "),
           !name.contains(".") {
            let baseName = String(name.dropLast())
            return ("\(baseName.capitalized) Service", .system)
        }

        // Agent pattern
        if name.hasSuffix("Agent") || name.hasSuffix("agent") {
            return ("\(name)", .system)
        }

        // Helper pattern
        if name.contains("Helper") || name.contains("helper") {
            return ("\(name)", .system)
        }

        // Extension pattern
        if name.hasSuffix("Extension") || name.hasSuffix("extension") {
            return ("\(name)", .system)
        }

        // Service pattern
        if name.hasSuffix("Service") || name.hasSuffix("service") {
            return ("\(name)", .system)
        }

        // XPC service pattern (common for sandboxed subprocesses)
        if name.contains("XPC") || name.contains("xpc") {
            return ("\(name)", .system)
        }

        return nil
    }

    // MARK: - Helpers

    private static func humanizeProcessRole(_ name: String) -> String {
        if name.contains("Helper") || name.contains("helper") { return "Helper" }
        if name.contains("Renderer") || name.contains("renderer") { return "Renderer" }
        if name.contains("GPU") || name.contains("gpu") { return "GPU Process" }
        if name.contains("Plugin") || name.contains("plugin") { return "Plugin" }
        if name.contains("Worker") || name.contains("worker") { return "Worker" }
        if name.contains("Utility") || name.contains("utility") { return "Utility" }
        if name.contains("Network") || name.contains("network") { return "Network" }
        if name.contains("Crash") { return "Crash Handler" }
        return "Background Process"
    }

    private static func humanizeDotNotation(_ name: String) -> String {
        // "WebKit.Networking" → "WebKit Networking"
        name.replacingOccurrences(of: ".", with: " ")
    }

    private static func describeSystemPath(name: String, path: String) -> String {
        // Provide context from the system path
        if path.contains("/PrivateFrameworks/") {
            return "\(name) (System Framework)"
        }
        if path.contains("/Frameworks/") {
            return "\(name) (Framework Service)"
        }
        if path.contains("/CoreServices/") {
            return "\(name) (Core Service)"
        }
        if path.contains("/PreferencePanes/") {
            return "\(name) (Preference Pane)"
        }
        if path.hasPrefix("/usr/libexec/") {
            return "\(name) (System Service)"
        }
        if path.hasPrefix("/usr/sbin/") {
            return "\(name) (System Admin)"
        }
        if path.hasPrefix("/usr/bin/") {
            return "\(name) (System Utility)"
        }
        return "\(name) (macOS)"
    }
}
