import SwiftUI

struct LucidTheme {

    // MARK: - Accent (Single, Muted)
    /// Primary accent: muted slate with subtle warmth
    /// Oklch-inspired: ~65% lightness, low chroma, cool hue
    static let accentPrimary = Color(red: 0.55, green: 0.62, blue: 0.70)

    /// Accent hover/pressed state: slightly lighter
    static let accentHover = Color(red: 0.62, green: 0.68, blue: 0.75)

    /// Accent muted: for secondary indicators
    static let accentMuted = Color(red: 0.40, green: 0.45, blue: 0.52)

    // MARK: - Backgrounds (3 Steps, Minimal Contrast)
    /// Base canvas: deep neutral dark
    static let backgroundBase = Color(red: 0.08, green: 0.08, blue: 0.09)

    /// Surface: cards, panels, sections
    static let backgroundSurface = Color(red: 0.12, green: 0.12, blue: 0.13)

    /// Elevated: popovers, modals, selected states
    static let backgroundElevated = Color(red: 0.16, green: 0.16, blue: 0.18)

    // MARK: - Safety Indicators (Muted, Cohesive)
    /// System/safe processes: muted teal (professional, non-alarming)
    static let safetySystem = Color(red: 0.45, green: 0.60, blue: 0.55)

    /// User processes: warm amber (distinguishable, earthy)
    static let safetyUser = Color(red: 0.70, green: 0.55, blue: 0.35)

    /// Unknown/suspicious: muted rose (attention without panic)
    static let safetyUnknown = Color(red: 0.75, green: 0.45, blue: 0.45)

    // MARK: - Text
    static let textPrimary = Color(white: 0.92)
    static let textSecondary = Color(white: 0.60)
    static let textTertiary = Color(white: 0.42)

    // MARK: - Borders (Subtle, consistent)
    static let borderSubtle = Color(white: 0.15)
    static let borderDefault = Color(white: 0.22)

    // MARK: - Status (Unified with safety palette)
    static let statusSuccess = safetySystem
    static let statusWarning = safetyUser
    static let statusCritical = safetyUnknown

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

    // MARK: - Legacy Aliases (for backward compatibility during transition)
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
