import SwiftUI

// MARK: - Flat Surface Modifiers (Glassmorphism removed for minimal aesthetic)

extension View {
    /// Flat surface for small elements (replaces glass)
    func lucidSurface() -> some View {
        modifier(LucidSurfaceModifier())
    }

    /// Flat container for larger sections
    func lucidSurfaceContainer() -> some View {
        modifier(LucidSurfaceContainerModifier())
    }

    /// Flat button style
    func lucidFlatButton() -> some View {
        modifier(LucidFlatButtonModifier())
    }

    // Legacy aliases - redirect to flat surfaces
    @available(*, deprecated, renamed: "lucidSurface")
    func lucidGlass() -> some View {
        lucidSurface()
    }

    @available(*, deprecated, renamed: "lucidSurfaceContainer")
    func lucidGlassContainer() -> some View {
        lucidSurfaceContainer()
    }

    @available(*, deprecated, renamed: "lucidFlatButton")
    func lucidGlassButton() -> some View {
        lucidFlatButton()
    }
}

// MARK: - LucidSurfaceModifier
struct LucidSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(LucidTheme.backgroundSurface)
            .cornerRadius(LucidTheme.cornerRadiusM)
    }
}

// MARK: - LucidSurfaceContainerModifier
struct LucidSurfaceContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(LucidTheme.backgroundSurface)
            .cornerRadius(LucidTheme.cornerRadiusL)
    }
}

// MARK: - LucidFlatButtonModifier
struct LucidFlatButtonModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, LucidTheme.spacingL)
            .padding(.vertical, LucidTheme.spacingS)
            .background(isHovered ? LucidTheme.backgroundElevated : LucidTheme.backgroundSurface)
            .cornerRadius(LucidTheme.cornerRadiusS)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Subtle Badge
struct SubtleBadgeModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, LucidTheme.spacingM)
            .padding(.vertical, LucidTheme.spacingXS)
            .background(color.opacity(0.1))
            .cornerRadius(LucidTheme.cornerRadiusS)
    }
}

extension View {
    func subtleBadge(color: Color) -> some View {
        modifier(SubtleBadgeModifier(color: color))
    }

    @available(*, deprecated, renamed: "subtleBadge")
    func glassEffectBadge(color: Color) -> some View {
        subtleBadge(color: color)
    }
}
