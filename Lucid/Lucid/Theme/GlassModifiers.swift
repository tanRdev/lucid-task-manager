import SwiftUI

extension View {
    func lucidGlass() -> some View {
        modifier(LucidGlassModifier())
    }

    func lucidGlassContainer() -> some View {
        modifier(LucidGlassContainerModifier())
    }

    func lucidGlassButton() -> some View {
        modifier(LucidGlassButtonModifier())
    }
}

// MARK: - LucidGlassModifier
struct LucidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(LucidTheme.cornerRadiusM)
        } else {
            content
                .background(LucidTheme.backgroundTertiary)
                .cornerRadius(LucidTheme.cornerRadiusM)
        }
    }
}

// MARK: - LucidGlassContainerModifier
struct LucidGlassContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content
                .background(.ultraThinMaterial)
                .cornerRadius(LucidTheme.cornerRadiusL)
        } else {
            content
                .background(LucidTheme.backgroundSecondary)
                .cornerRadius(LucidTheme.cornerRadiusL)
        }
    }
}

// MARK: - LucidGlassButtonModifier
struct LucidGlassButtonModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content
                .padding(.horizontal, LucidTheme.spacingL)
                .padding(.vertical, LucidTheme.spacingS)
                .background(.ultraThinMaterial)
                .cornerRadius(LucidTheme.cornerRadiusS)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovered = hovering
                    }
                }
                .scaleEffect(isHovered ? 1.02 : 1.0)
        } else {
            content
                .padding(.horizontal, LucidTheme.spacingL)
                .padding(.vertical, LucidTheme.spacingS)
                .background(LucidTheme.backgroundTertiary)
                .cornerRadius(LucidTheme.cornerRadiusS)
        }
    }
}

// MARK: - Glass Effect Badge
struct GlassEffectBadge: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content
                .padding(.horizontal, LucidTheme.spacingM)
                .padding(.vertical, LucidTheme.spacingXS)
                .background(.ultraThinMaterial)
                .cornerRadius(LucidTheme.cornerRadiusS)
                .overlay(
                    RoundedRectangle(cornerRadius: LucidTheme.cornerRadiusS)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        } else {
            content
                .padding(.horizontal, LucidTheme.spacingM)
                .padding(.vertical, LucidTheme.spacingXS)
                .background(LucidTheme.backgroundTertiary)
                .cornerRadius(LucidTheme.cornerRadiusS)
        }
    }
}

extension View {
    func glassEffectBadge(color: Color) -> some View {
        modifier(GlassEffectBadge(color: color))
    }
}
