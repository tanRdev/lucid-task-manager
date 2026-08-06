import SwiftUI

/// Heuristic ownership/origin of a process — not a guarantee that termination is safe.
enum ProcessOrigin: String, Codable, Hashable, Sendable {
    case system
    case user
    case unknown

    /// System-origin processes are protected from termination by default.
    var isProtected: Bool {
        self == .system
    }

    var allowsTermination: Bool {
        !isProtected
    }

    /// Origins whose termination is permitted but only after an explicit
    /// extra confirmation step — the classification evidence was too weak
    /// to trust a single-click kill.
    var requiresConfirmation: Bool {
        self == .unknown
    }

    var color: Color {
        switch self {
        case .system:
            return LucidTheme.originSystem
        case .user:
            return LucidTheme.originUser
        case .unknown:
            return LucidTheme.originUnknown
        }
    }

    var label: String {
        switch self {
        case .system:
            return "System"
        case .user:
            return "User"
        case .unknown:
            return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .system:
            return "gearshape.fill"
        case .user:
            return "person.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}
