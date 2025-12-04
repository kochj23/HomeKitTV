import SwiftUI

/// Dynamic layout calculator for tvOS screens
///
/// Calculates optimal card sizes and grid layout to fit all content on one screen
/// without scrolling. Designed for 1920x1080 (Full HD) Apple TV displays.
///
/// **tvOS Screen Dimensions**:
/// - Full HD: 1920x1080
/// - Safe area (top): ~60px (status bar)
/// - Safe area (bottom): ~100px (tab bar)
/// - Available height: ~920px
/// - Available width: ~1920px
///
/// **Memory Safety**: Struct-based, no retain cycles
struct DynamicLayoutCalculator {
    /// tvOS safe screen dimensions
    static let tvSafeWidth: CGFloat = 1920
    static let tvSafeHeight: CGFloat = 820  // 1080 - 60 (top) - 100 (tab bar) - 100 (buffer)

    /// Calculate optimal card size based on item count
    /// - Parameters:
    ///   - itemCount: Total number of items to display
    ///   - availableWidth: Available screen width
    ///   - availableHeight: Available screen height
    ///   - headerHeight: Height reserved for header/title
    /// - Returns: Optimal card size that fits all items
    static func calculateCardSize(
        itemCount: Int,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        headerHeight: CGFloat = 120
    ) -> CGSize {
        let contentHeight = availableHeight - headerHeight
        let contentWidth = availableWidth - 120  // 60px padding each side

        guard itemCount > 0 else {
            return CGSize(width: 300, height: 200)
        }

        // Calculate optimal grid dimensions
        let columns = optimalColumns(for: itemCount, width: contentWidth)
        let rows = Int(ceil(Double(itemCount) / Double(columns)))

        // Calculate card size with spacing
        let horizontalSpacing: CGFloat = 20
        let verticalSpacing: CGFloat = 20

        let cardWidth = (contentWidth - (CGFloat(columns - 1) * horizontalSpacing)) / CGFloat(columns)
        let cardHeight = (contentHeight - (CGFloat(rows - 1) * verticalSpacing)) / CGFloat(rows)

        // Ensure minimum readable size
        let minWidth: CGFloat = 200
        let minHeight: CGFloat = 120

        return CGSize(
            width: max(minWidth, cardWidth),
            height: max(minHeight, cardHeight)
        )
    }

    /// Calculate optimal number of columns based on item count and screen width
    private static func optimalColumns(for itemCount: Int, width: CGFloat) -> Int {
        switch itemCount {
        case 0...4: return min(itemCount, 4)
        case 5...8: return 4
        case 9...12: return 4
        case 13...16: return 5
        case 17...20: return 5
        default: return 6
        }
    }

    /// Calculate dynamic font scale based on card size
    /// - Parameter cardSize: Size of the card
    /// - Returns: Font scale multiplier
    static func fontScale(for cardSize: CGSize) -> CGFloat {
        let baseCardSize: CGFloat = 300  // Original card width
        let scale = cardSize.width / baseCardSize
        return max(0.15, min(scale * 0.25, 0.35))  // Clamp between 0.15x and 0.35x
    }

    /// Calculate grid spacing based on available space
    static func gridSpacing(for availableWidth: CGFloat, columns: Int) -> CGFloat {
        if columns <= 3 {
            return 25
        } else if columns <= 5 {
            return 20
        } else {
            return 15
        }
    }
}

/// View modifier to apply dynamic sizing to cards
struct DynamicCardStyle: ViewModifier {
    let size: CGSize
    let fontScale: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .environment(\.dynamicTypeSize, .large)  // Base type size
    }
}

extension View {
    func dynamicCardStyle(size: CGSize, fontScale: CGFloat) -> some View {
        modifier(DynamicCardStyle(size: size, fontScale: fontScale))
    }
}
