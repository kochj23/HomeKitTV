//
//  PlatformHelpers.swift
//  HomeKitTV
//
//  Platform-specific helpers for tvOS and iOS (iPad)
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Detection

#if os(tvOS)
private let _isTV = true
private let _isiOS = false
#elseif os(iOS)
private let _isTV = false
private let _isiOS = true
#else
private let _isTV = false
private let _isiOS = false
#endif

// MARK: - Platform Constants

struct PlatformConstants {
    static let isTV: Bool = _isTV
    static let isiOS: Bool = _isiOS

    static var isiPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    /// Current screen bounds
    static var screenBounds: CGRect {
        #if os(tvOS)
        return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #elseif os(iOS)
        return UIScreen.main.bounds
        #else
        return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #endif
    }

    /// Safe area for content
    static var safeWidth: CGFloat {
        if isTV {
            return 1920
        } else if isiPad {
            return min(screenBounds.width, screenBounds.height) // Use smaller dimension for consistency
        } else {
            return screenBounds.width
        }
    }

    static var safeHeight: CGFloat {
        if isTV {
            return 820 // TV safe area
        } else if isiPad {
            return max(screenBounds.width, screenBounds.height) - 100 // Account for tab bar
        } else {
            return screenBounds.height - 100
        }
    }

    /// Font size scale factor
    static var fontScale: CGFloat {
        isTV ? 1.5 : 1.0
    }

    /// Padding scale factor
    static var paddingScale: CGFloat {
        isTV ? 2.0 : (isiPad ? 1.2 : 1.0)
    }

    /// Corner radius for cards
    static var cornerRadius: CGFloat {
        isTV ? 20 : 12
    }

    /// Minimum card width
    static var minCardWidth: CGFloat {
        isTV ? 300 : (isiPad ? 200 : 160)
    }

    /// Grid spacing
    static var gridSpacing: CGFloat {
        isTV ? 20 : (isiPad ? 16 : 12)
    }

    /// Horizontal padding
    static var horizontalPadding: CGFloat {
        isTV ? 60 : (isiPad ? 24 : 16)
    }

    /// Icon size for cards
    static var cardIconSize: CGFloat {
        isTV ? 50 : (isiPad ? 36 : 28)
    }

    /// Header height
    static var headerHeight: CGFloat {
        isTV ? 120 : (isiPad ? 80 : 60)
    }
}

// MARK: - Platform-Adaptive Font

extension Font {
    static func platformTitle() -> Font {
        .system(size: PlatformConstants.isTV ? 48 : 28, weight: .bold, design: .rounded)
    }

    static func platformLargeTitle() -> Font {
        .system(size: PlatformConstants.isTV ? 36 : 24, weight: .bold, design: .rounded)
    }

    static func platformHeadline() -> Font {
        .system(size: PlatformConstants.isTV ? 28 : 20, weight: .semibold, design: .rounded)
    }

    static func platformSubheadline() -> Font {
        .system(size: PlatformConstants.isTV ? 24 : 17, weight: .medium)
    }

    static func platformBody() -> Font {
        .system(size: PlatformConstants.isTV ? 22 : 16)
    }

    static func platformCaption() -> Font {
        .system(size: PlatformConstants.isTV ? 18 : 13)
    }

    static func platformFootnote() -> Font {
        .system(size: PlatformConstants.isTV ? 16 : 12)
    }

    /// Dynamic font scaled for card size
    static func cardFont(for cardSize: CGSize, style: CardFontStyle) -> Font {
        let baseSize: CGFloat
        switch style {
        case .title: baseSize = PlatformConstants.isTV ? 28 : 18
        case .subtitle: baseSize = PlatformConstants.isTV ? 20 : 14
        case .caption: baseSize = PlatformConstants.isTV ? 16 : 12
        }

        let scale = min(cardSize.width / 300, 1.5)
        return .system(size: baseSize * scale, weight: style == .title ? .semibold : .regular)
    }

    enum CardFontStyle {
        case title
        case subtitle
        case caption
    }
}

// MARK: - Platform View Modifiers

extension View {
    /// Apply platform-specific padding
    func platformPadding(_ edges: Edge.Set = .all, _ amount: CGFloat = 16) -> some View {
        self.padding(edges, amount * PlatformConstants.paddingScale)
    }

    /// Apply card styling appropriate for platform
    func platformCardStyle(isOn: Bool = false) -> some View {
        self
            .background(isOn ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(PlatformConstants.cornerRadius)
    }

    /// Apply hover effect on iPad (pointer support)
    @ViewBuilder
    func iPadHoverEffect() -> some View {
        #if os(iOS)
        self.hoverEffect(.highlight)
        #else
        self
        #endif
    }
}

// MARK: - Adaptive Grid Helper

struct AdaptiveGridLayout {
    /// Calculate optimal number of columns for given width
    static func columns(for width: CGFloat, itemCount: Int) -> Int {
        let minItemWidth = PlatformConstants.minCardWidth
        let spacing = PlatformConstants.gridSpacing
        let padding = PlatformConstants.horizontalPadding * 2
        let availableWidth = width - padding

        let maxColumns = Int(availableWidth / (minItemWidth + spacing))

        if PlatformConstants.isTV {
            // TV-specific column calculation
            switch itemCount {
            case 0...4: return min(itemCount, 4)
            case 5...8: return 4
            case 9...12: return 4
            case 13...16: return 5
            case 17...20: return 5
            default: return 6
            }
        } else {
            // iPad adaptive columns
            return max(2, min(maxColumns, 6))
        }
    }

    /// Create grid columns for LazyVGrid
    static func gridItems(for width: CGFloat, itemCount: Int) -> [GridItem] {
        let columnCount = columns(for: width, itemCount: itemCount)
        let spacing = PlatformConstants.gridSpacing
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    /// Calculate card size for given parameters
    static func cardSize(
        for width: CGFloat,
        height: CGFloat,
        itemCount: Int,
        headerHeight: CGFloat = PlatformConstants.headerHeight
    ) -> CGSize {
        let columns = columns(for: width, itemCount: itemCount)
        let rows = Int(ceil(Double(itemCount) / Double(columns)))

        let spacing = PlatformConstants.gridSpacing
        let padding = PlatformConstants.horizontalPadding * 2

        let availableWidth = width - padding - (CGFloat(columns - 1) * spacing)
        let availableHeight = height - headerHeight - (CGFloat(rows - 1) * spacing)

        let cardWidth = availableWidth / CGFloat(columns)
        let cardHeight = availableHeight / CGFloat(max(rows, 1))

        let minWidth = PlatformConstants.minCardWidth
        let minHeight: CGFloat = PlatformConstants.isTV ? 120 : 100

        return CGSize(
            width: max(minWidth, cardWidth),
            height: max(minHeight, cardHeight)
        )
    }
}

// MARK: - Screen Size Reader

struct ScreenSizeReader<Content: View>: View {
    let content: (CGSize) -> Content

    init(@ViewBuilder content: @escaping (CGSize) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            content(geometry.size)
        }
    }
}
