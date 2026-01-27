import SwiftUI

struct LucidTheme {
    // MARK: - Primary Colors
    static let accentOrange = Color(red: 1.0, green: 0.35, blue: 0.0) // #FF5C00
    static let accentOrangeLight = Color(red: 1.0, green: 0.5, blue: 0.2)

    // MARK: - Background Colors
    static let backgroundDark = Color(red: 0.06, green: 0.06, blue: 0.07) // #0A0A0B
    static let backgroundSecondary = Color(red: 0.08, green: 0.08, blue: 0.1)
    static let backgroundTertiary = Color(red: 0.12, green: 0.12, blue: 0.14)

    // MARK: - Safety Colors
    static let safetySystem = Color(red: 0.2, green: 0.8, blue: 0.2) // Green
    static let safetyUser = Color(red: 0.9, green: 0.7, blue: 0.1) // Yellow/Orange
    static let safetyUnknown = Color(red: 0.8, green: 0.2, blue: 0.2) // Red

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textTertiary = Color(white: 0.4)

    // MARK: - Border Colors
    static let borderPrimary = Color(red: 0.15, green: 0.15, blue: 0.2)
    static let borderSecondary = Color(red: 0.1, green: 0.1, blue: 0.12)

    // MARK: - Font Sizes
    static let fontSizeXS: CGFloat = 10
    static let fontSizeS: CGFloat = 12
    static let fontSizeBase: CGFloat = 14
    static let fontSizeL: CGFloat = 16
    static let fontSizeXL: CGFloat = 20
    static let fontSize2XL: CGFloat = 28

    // MARK: - Spacing
    static let spacing2XS: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacing2XL: CGFloat = 32

    // MARK: - Badge / Interactive Colors
    static let badgeBackground = Color(red: 0.2, green: 0.2, blue: 0.25)

    // MARK: - Metric Colors
    static let metricCPU = Color(red: 1.0, green: 0.35, blue: 0.0)
    static let metricMemory = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let metricProcesses = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let metricDisk = Color(red: 1.0, green: 0.6, blue: 0.2)

    // MARK: - Corner Radius
    static let cornerRadiusS: CGFloat = 4
    static let cornerRadiusM: CGFloat = 8
    static let cornerRadiusL: CGFloat = 12
}
