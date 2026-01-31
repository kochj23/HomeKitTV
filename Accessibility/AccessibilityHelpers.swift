//
//  AccessibilityHelpers.swift
//  HomeKitTV
//
//  Accessibility helpers for DynamicType, VoiceOver, and Reduce Motion
//  Ensures app is accessible to all users
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

// MARK: - Dynamic Type Scaling

/// Environment key for custom text scaling
struct DynamicTypeSizeKey: EnvironmentKey {
    static let defaultValue: DynamicTypeSize = .medium
}

extension EnvironmentValues {
    var appDynamicTypeSize: DynamicTypeSize {
        get { self[DynamicTypeSizeKey.self] }
        set { self[DynamicTypeSizeKey.self] = newValue }
    }
}

// MARK: - Scaled Font Extension

extension Font {
    /// Creates a font that scales with Dynamic Type
    static func scaledFont(_ style: TextStyle, size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Predefined scaled fonts for HomeKitTV
    static var scaledTitle: Font { .system(.title, design: .default, weight: .bold) }
    static var scaledHeadline: Font { .system(.headline, design: .default, weight: .semibold) }
    static var scaledBody: Font { .system(.body, design: .default) }
    static var scaledCallout: Font { .system(.callout, design: .default) }
    static var scaledCaption: Font { .system(.caption, design: .default) }
    static var scaledCaption2: Font { .system(.caption2, design: .default) }
}

// MARK: - Accessibility View Modifier

struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    /// Adds accessibility support with label, hint, and traits
    func accessibilitySupport(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilityModifier(label: label, hint: hint, traits: traits))
    }

    /// Makes a button accessible
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        accessibilitySupport(label: label, hint: hint, traits: .isButton)
    }

    /// Makes a header accessible
    func accessibleHeader(_ label: String) -> some View {
        accessibilitySupport(label: label, traits: .isHeader)
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

extension View {
    /// Applies animation respecting Reduce Motion setting
    func accessibleAnimation(_ animation: Animation = .default) -> some View {
        modifier(ReduceMotionModifier(animation: animation, reducedAnimation: .linear(duration: 0)))
    }
}

// MARK: - VoiceOver Announcement

struct VoiceOverAnnouncer {
    /// Announces a message to VoiceOver users
    static func announce(_ message: String, priority: UIAccessibility.Priority = .low) {
        #if os(iOS) || os(tvOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }

    /// Announces screen change to VoiceOver users
    static func announceScreenChange(_ message: String? = nil) {
        #if os(iOS) || os(tvOS)
        UIAccessibility.post(notification: .screenChanged, argument: message)
        #endif
    }

    /// Announces layout change to VoiceOver users
    static func announceLayoutChange(_ element: Any? = nil) {
        #if os(iOS) || os(tvOS)
        UIAccessibility.post(notification: .layoutChanged, argument: element)
        #endif
    }
}

// MARK: - Accessible Card Component

struct AccessibleCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let content: Content

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize))
                        .foregroundColor(.cyan)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.scaledHeadline)
                        .accessibilityAddTraits(.isHeader)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.scaledCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            content
        }
        .padding(padding)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(cornerRadius)
        .accessibilityElement(children: .contain)
    }

    // Adaptive sizing based on Dynamic Type
    private var iconSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 16
        case .medium, .large: return 20
        case .xLarge, .xxLarge: return 24
        case .xxxLarge: return 28
        case .accessibility1, .accessibility2: return 32
        case .accessibility3, .accessibility4, .accessibility5: return 40
        @unknown default: return 20
        }
    }

    private var spacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 12
    }

    private var padding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 20 : 16
    }

    private var cornerRadius: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 12
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(configuration.isPressed ? Color.cyan.opacity(0.3) : Color.cyan.opacity(0.2))
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }

    private var horizontalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 20 : 16
    }

    private var verticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 10
    }

    private var cornerRadius: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 10
    }
}

extension ButtonStyle where Self == AccessibleButtonStyle {
    static var accessible: AccessibleButtonStyle { AccessibleButtonStyle() }
}

// MARK: - Accessibility Manager

@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()

    @Published var isVoiceOverRunning: Bool = false
    @Published var isSwitchControlRunning: Bool = false
    @Published var prefersBoldText: Bool = false
    @Published var prefersReduceMotion: Bool = false
    @Published var prefersReduceTransparency: Bool = false

    private init() {
        updateAccessibilityStatus()
        setupNotifications()
    }

    private func updateAccessibilityStatus() {
        #if os(iOS) || os(tvOS)
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        prefersBoldText = UIAccessibility.isBoldTextEnabled
        prefersReduceMotion = UIAccessibility.isReduceMotionEnabled
        prefersReduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        #endif
    }

    private func setupNotifications() {
        #if os(iOS) || os(tvOS)
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilityStatus()
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilityStatus()
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilityStatus()
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAccessibilityStatus()
        }
        #endif
    }

    /// Get appropriate animation duration based on accessibility settings
    var animationDuration: Double {
        prefersReduceMotion ? 0 : 0.3
    }

    /// Get appropriate animation
    var animation: Animation? {
        prefersReduceMotion ? nil : .easeInOut(duration: 0.3)
    }
}

// MARK: - Accessible List Row

struct AccessibleListRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let value: String?
    let action: (() -> Void)?

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        value: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.value = value
        self.action = action
    }

    var body: some View {
        let row = HStack(spacing: spacing) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize))
                .foregroundColor(.cyan)
                .frame(width: iconSize + 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.scaledBody)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.scaledCaption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let value = value {
                Text(value)
                    .font(.scaledCallout)
                    .foregroundColor(.secondary)
            }

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.scaledCaption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, verticalPadding)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(action != nil ? "Double tap to open" : "")
        .accessibilityAddTraits(action != nil ? .isButton : [])

        if let action = action {
            Button(action: action) {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }

    private var iconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 28 : 22
    }

    private var spacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 16 : 12
    }

    private var verticalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 12 : 8
    }

    private var accessibilityLabel: String {
        var label = title
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        if let value = value {
            label += ", \(value)"
        }
        return label
    }
}

// MARK: - Dynamic Type Size Extension

extension DynamicTypeSize {
    /// Returns true if the size is one of the accessibility sizes
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }

    /// Returns a multiplier for custom sizing
    var scaleFactor: CGFloat {
        switch self {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        case .accessibility1: return 1.6
        case .accessibility2: return 1.8
        case .accessibility3: return 2.0
        case .accessibility4: return 2.2
        case .accessibility5: return 2.4
        @unknown default: return 1.0
        }
    }
}
