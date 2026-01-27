import SwiftUI

enum Safety: String, Codable, Hashable {
    case system
    case user
    case unknown

    var color: Color {
        switch self {
        case .system:
            return LucidTheme.safetySystem
        case .user:
            return LucidTheme.safetyUser
        case .unknown:
            return LucidTheme.safetyUnknown
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
