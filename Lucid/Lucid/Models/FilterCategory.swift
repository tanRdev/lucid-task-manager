import Foundation

enum FilterCategory: Hashable {
    case all
    case system
    case user
    case unknown
    case port(UInt16)
}
