import SwiftUI

enum Safety: String, Codable, Hashable {
    case system
    case user
    case unknown

    var color: Color {
        switch self {
        case .system:
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Green
        case .user:
            return Color(red: 0.9, green: 0.7, blue: 0.1) // Yellow/Orange
        case .unknown:
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
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
