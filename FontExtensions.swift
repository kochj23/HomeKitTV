import SwiftUI

/// Font scaling extension for dynamic font sizes
///
/// This extension provides methods to scale fonts based on user preferences.
/// All font sizes are multiplied by the Settings.fontSizeMultiplier value.
///
/// **Usage**:
/// ```swift
/// Text("Hello")
///     .font(.scaledTitle)
///     .scaledPadding()
/// ```
///
/// **Memory Safety**: No memory issues - extension methods don't capture state
extension View {
    /// Applies scaled title font
    func scaledTitleFont() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 48 * multiplier, weight: .bold))
    }

    /// Applies scaled large title font
    func scaledLargeTitleFont() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 42 * multiplier, weight: .bold))
    }

    /// Applies scaled title2 font
    func scaledTitle2Font() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 36 * multiplier, weight: .bold))
    }

    /// Applies scaled title3 font
    func scaledTitle3Font() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 28 * multiplier, weight: .semibold))
    }

    /// Applies scaled body font
    func scaledBodyFont() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 22 * multiplier))
    }

    /// Applies scaled caption font
    func scaledCaptionFont() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        return self.font(.system(size: 18 * multiplier))
    }

    /// Applies scaled padding
    func scaledPadding(_ edges: Edge.Set = .all) -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        let basePadding: CGFloat = 20
        return self.padding(edges, basePadding * multiplier)
    }

    /// Applies scaled horizontal padding
    func scaledHorizontalPadding() -> some View {
        let multiplier = Settings.shared.fontSizeMultiplier
        let basePadding: CGFloat = 80
        return self.padding(.horizontal, basePadding * multiplier)
    }
}

/// Font size enum for settings
enum FontSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .small: return 0.2      // Was 0.8, reduced to 25% of original
        case .medium: return 0.25    // Was 1.0, reduced to 25% of original
        case .large: return 0.3      // Was 1.2, reduced to 25% of original
        case .extraLarge: return 0.35 // Was 1.4, reduced to 25% of original
        }
    }

    static func from(multiplier: Double) -> FontSize {
        switch multiplier {
        case 0..<0.225: return .small
        case 0.225..<0.275: return .medium
        case 0.275..<0.325: return .large
        default: return .extraLarge
        }
    }
}
