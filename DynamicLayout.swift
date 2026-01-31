import SwiftUI

/// Dynamic layout calculator for tvOS and iPad screens
///
/// Calculates optimal card sizes and grid layout to fit content appropriately.
/// Adapts to different screen sizes:
///
/// **tvOS Screen Dimensions**:
/// - Full HD: 1920x1080
/// - Safe area (top): ~60px (status bar)
/// - Safe area (bottom): ~100px (tab bar)
/// - Available height: ~920px
///
/// **iPad Screen Dimensions** (varies by model):
/// - iPad Pro 12.9": 1024x1366
/// - iPad Pro 11": 834x1194
/// - iPad Air/mini: various
///
/// **Memory Safety**: Struct-based, no retain cycles
struct DynamicLayoutCalculator {
    /// Platform-aware safe screen dimensions
    static var safeWidth: CGFloat {
        PlatformConstants.safeWidth
    }

    static var safeHeight: CGFloat {
        PlatformConstants.safeHeight
    }

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
        headerHeight: CGFloat? = nil
    ) -> CGSize {
        let effectiveHeaderHeight = headerHeight ?? PlatformConstants.headerHeight
        let contentHeight = availableHeight - effectiveHeaderHeight
        let padding = PlatformConstants.horizontalPadding * 2
        let contentWidth = availableWidth - padding

        guard itemCount > 0 else {
            let defaultWidth = PlatformConstants.isTV ? 300 : 200
            let defaultHeight = PlatformConstants.isTV ? 200 : 150
            return CGSize(width: CGFloat(defaultWidth), height: CGFloat(defaultHeight))
        }

        // Calculate optimal grid dimensions
        let columns = optimalColumns(for: itemCount, width: contentWidth)
        let rows = Int(ceil(Double(itemCount) / Double(columns)))

        // Calculate card size with spacing
        let spacing = PlatformConstants.gridSpacing

        let cardWidth = (contentWidth - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
        let cardHeight = (contentHeight - (CGFloat(rows - 1) * spacing)) / CGFloat(rows)

        // Ensure minimum readable size (platform-aware)
        let minWidth = PlatformConstants.minCardWidth
        let minHeight: CGFloat = PlatformConstants.isTV ? 120 : 100

        return CGSize(
            width: max(minWidth, cardWidth),
            height: max(minHeight, cardHeight)
        )
    }

    /// Calculate optimal number of columns based on item count and screen width
    private static func optimalColumns(for itemCount: Int, width: CGFloat) -> Int {
        if PlatformConstants.isTV {
            // tvOS: fixed column layouts for consistency
            switch itemCount {
            case 0...4: return min(itemCount, 4)
            case 5...8: return 4
            case 9...12: return 4
            case 13...16: return 5
            case 17...20: return 5
            default: return 6
            }
        } else {
            // iPad: adaptive columns based on screen width
            let minItemWidth = PlatformConstants.minCardWidth
            let spacing = PlatformConstants.gridSpacing
            let maxColumns = Int(width / (minItemWidth + spacing))
            return max(2, min(maxColumns, itemCount))
        }
    }

    /// Calculate dynamic font scale based on card size
    /// - Parameter cardSize: Size of the card
    /// - Returns: Font scale multiplier
    static func fontScale(for cardSize: CGSize) -> CGFloat {
        let baseCardSize: CGFloat = PlatformConstants.isTV ? 300 : 200
        let scale = cardSize.width / baseCardSize

        if PlatformConstants.isTV {
            return max(0.15, min(scale * 0.25, 0.35))
        } else {
            return max(0.8, min(scale, 1.2))
        }
    }

    /// Calculate grid spacing based on available space
    static func gridSpacing(for availableWidth: CGFloat, columns: Int) -> CGFloat {
        if PlatformConstants.isTV {
            if columns <= 3 {
                return 25
            } else if columns <= 5 {
                return 20
            } else {
                return 15
            }
        } else {
            return PlatformConstants.gridSpacing
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
