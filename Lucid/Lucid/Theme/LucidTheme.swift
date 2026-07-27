import SwiftUI
import AppKit

struct LucidTheme {

    // MARK: - Accent (Vibrant, Cool)
    static let accentPrimary = Color(
        light: Color(red: 0.20, green: 0.50, blue: 0.90),
        dark: Color(red: 0.35, green: 0.65, blue: 1.0)
    )

    static let accentHover = Color(
        light: Color(red: 0.30, green: 0.60, blue: 0.95),
        dark: Color(red: 0.50, green: 0.75, blue: 1.0)
    )

    static let accentMuted = Color(
        light: Color(red: 0.15, green: 0.35, blue: 0.65),
        dark: Color(red: 0.25, green: 0.45, blue: 0.75)
    )

    // MARK: - Backgrounds
    static let backgroundBase = Color(
        light: Color(white: 0.97),
        dark: Color(red: 0.05, green: 0.05, blue: 0.06)
    )

    static let backgroundSurface = Color(
        light: Color(white: 0.94),
        dark: Color(red: 0.08, green: 0.09, blue: 0.10)
    )

    static let backgroundElevated = Color(
        light: Color(white: 0.90),
        dark: Color(red: 0.12, green: 0.13, blue: 0.15)
    )

    // MARK: - Origin Indicators (neutral semantic — not "safe/unsafe")
    static let originSystem = Color(
        light: Color(red: 0.35, green: 0.40, blue: 0.48),
        dark: Color(red: 0.55, green: 0.60, blue: 0.68)
    )

    static let originUser = Color(
        light: Color(red: 0.20, green: 0.45, blue: 0.75),
        dark: Color(red: 0.45, green: 0.65, blue: 0.90)
    )

    static let originUnknown = Color(
        light: Color(red: 0.55, green: 0.45, blue: 0.25),
        dark: Color(red: 0.75, green: 0.65, blue: 0.40)
    )

    // Legacy aliases
    static let safetySystem = originSystem
    static let safetyUser = originUser
    static let safetyUnknown = originUnknown

    // MARK: - Text
    static let textPrimary = Color(
        light: Color(white: 0.10),
        dark: Color(white: 0.92)
    )

    static let textSecondary = Color(
        light: Color(white: 0.40),
        dark: Color(white: 0.60)
    )

    static let textTertiary = Color(
        light: Color(white: 0.55),
        dark: Color(white: 0.42)
    )

    // MARK: - Borders
    static let borderSubtle = Color(
        light: Color(white: 0.85),
        dark: Color(white: 0.15)
    )

    static let borderDefault = Color(
        light: Color(white: 0.78),
        dark: Color(white: 0.22)
    )

    // MARK: - Status
    static let statusSuccess = Color(red: 0.20, green: 0.70, blue: 0.45)
    static let statusWarning = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let statusCritical = Color(red: 0.85, green: 0.30, blue: 0.25)

    // MARK: - Typography Scale
    static let fontSizeXS: CGFloat = 10
    static let fontSizeS: CGFloat = 12
    static let fontSizeBase: CGFloat = 14
    static let fontSizeL: CGFloat = 16
    static let fontSizeXL: CGFloat = 20
    static let fontSize2XL: CGFloat = 28

    // MARK: - Spacing Scale
    static let spacing2XS: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacing2XL: CGFloat = 32

    // MARK: - Component Colors
    static let badgeBackground = backgroundElevated
    static let divider = borderSubtle

    // MARK: - Corner Radius
    static let cornerRadiusS: CGFloat = 4
    static let cornerRadiusM: CGFloat = 8
    static let cornerRadiusL: CGFloat = 12

    // MARK: - Legacy Aliases
    static let accentOrange = accentPrimary
    static let accentOrangeLight = accentHover
    static let backgroundDark = backgroundBase
    static let backgroundSecondary = backgroundSurface
    static let backgroundTertiary = backgroundElevated
    static let borderPrimary = borderDefault
    static let borderSecondary = borderSubtle
    static let metricCPU = accentPrimary
    static let metricMemory = accentPrimary.opacity(0.8)
    static let metricProcesses = accentPrimary.opacity(0.6)
    static let metricDisk = accentPrimary.opacity(0.4)
}

extension Color {
    init(light: Color, dark: Color) {
        let nsColor = NSColor(name: nil) { appearance in
            if appearance.name == .darkAqua {
                return NSColor(dark)
            }
            return NSColor(light)
        }
        self.init(nsColor)
    }
}
