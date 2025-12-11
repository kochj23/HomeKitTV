import Foundation
import HomeKit
import SwiftUI

// MARK: - HomeKit Error Types

/// Enhanced error types for HomeKit operations with recovery suggestions
///
/// Provides user-friendly error messages and actionable recovery steps.
///
/// **Author**: Jordan Koch
enum HomeKitError: LocalizedError {
    case accessoryUnreachable(accessory: HMAccessory)
    case sceneExecutionFailed(scene: HMActionSet, failedDevices: [HMAccessory])
    case authorizationDenied
    case networkUnavailable
    case characteristicNotFound(name: String)
    case writeValueFailed(characteristic: String, error: Error)
    case readValueFailed(characteristic: String, error: Error)
    case homeNotAvailable
    case operationTimeout
    case rateLimitExceeded
    case invalidInput(field: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .accessoryUnreachable(let accessory):
            return "\(accessory.name) is not responding"

        case .sceneExecutionFailed(let scene, let failed):
            if failed.count == 1 {
                return "Scene '\(scene.name)' failed: \(failed[0].name) didn't respond"
            } else {
                return "Scene '\(scene.name)' partially executed. \(failed.count) device(s) failed."
            }

        case .authorizationDenied:
            return "HomeKit Access Denied"

        case .networkUnavailable:
            return "Network connection unavailable"

        case .characteristicNotFound(let name):
            return "Accessory doesn't support \(name)"

        case .writeValueFailed(let characteristic, let error):
            return "Failed to set \(characteristic): \(error.localizedDescription)"

        case .readValueFailed(let characteristic, let error):
            return "Failed to read \(characteristic): \(error.localizedDescription)"

        case .homeNotAvailable:
            return "No home configured"

        case .operationTimeout:
            return "Operation timed out"

        case .rateLimitExceeded:
            return "Too many commands. Please wait."

        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .accessoryUnreachable:
            return "Try: 1. Check if device is powered on, 2. Check Wi-Fi connection, 3. Restart the device"

        case .sceneExecutionFailed:
            return "Tap 'Retry' to try again, or tap 'Details' to see which devices failed"

        case .authorizationDenied:
            return "Go to Settings > Privacy > HomeKit and enable access for this app"

        case .networkUnavailable:
            return "Check your Wi-Fi or network connection and try again"

        case .characteristicNotFound:
            return "This accessory doesn't support this feature. Check accessory capabilities."

        case .writeValueFailed, .readValueFailed:
            return "Device may be busy. Wait a moment and try again."

        case .homeNotAvailable:
            return "Set up a home in the Home app on your iPhone or iPad first"

        case .operationTimeout:
            return "Device took too long to respond. Check network connection and device status."

        case .rateLimitExceeded:
            return "You're sending commands too quickly. Wait a few seconds and try again."

        case .invalidInput:
            return "Please check your input and try again"
        }
    }

    var failureReason: String? {
        switch self {
        case .accessoryUnreachable:
            return "Device is offline or not responding to HomeKit commands"

        case .sceneExecutionFailed:
            return "One or more devices in the scene failed to execute"

        case .authorizationDenied:
            return "App doesn't have permission to access HomeKit"

        case .networkUnavailable:
            return "Cannot reach HomeKit hub or accessories"

        case .operationTimeout:
            return "Device didn't respond within expected time"

        case .rateLimitExceeded:
            return "Command rate limit exceeded to prevent hub overload"

        default:
            return nil
        }
    }

    /// Recovery actions available for this error
    var recoveryActions: [RecoveryAction] {
        switch self {
        case .accessoryUnreachable:
            return [.retry, .checkStatus, .openHomeApp]

        case .sceneExecutionFailed:
            return [.retry, .viewDetails, .editScene]

        case .authorizationDenied:
            return [.openSettings]

        case .networkUnavailable:
            return [.retry, .checkNetwork]

        case .writeValueFailed, .readValueFailed:
            return [.retry, .viewDetails]

        case .homeNotAvailable:
            return [.openHomeApp]

        case .operationTimeout:
            return [.retry, .checkStatus]

        case .rateLimitExceeded:
            return [.waitAndRetry]

        case .invalidInput:
            return [.edit]

        default:
            return [.dismiss]
        }
    }
}

// MARK: - Recovery Actions

/// Available recovery actions for errors
enum RecoveryAction: String, CaseIterable {
    case retry = "Retry"
    case viewDetails = "View Details"
    case checkStatus = "Check Status"
    case openHomeApp = "Open Home App"
    case openSettings = "Open Settings"
    case editScene = "Edit Scene"
    case checkNetwork = "Check Network"
    case waitAndRetry = "Wait & Retry"
    case edit = "Edit"
    case dismiss = "Dismiss"

    var icon: String {
        switch self {
        case .retry, .waitAndRetry:
            return "arrow.clockwise"
        case .viewDetails:
            return "info.circle"
        case .checkStatus:
            return "checkmark.circle"
        case .openHomeApp:
            return "house.fill"
        case .openSettings:
            return "gearshape.fill"
        case .editScene:
            return "pencil"
        case .checkNetwork:
            return "wifi"
        case .edit:
            return "pencil.circle"
        case .dismiss:
            return "xmark.circle"
        }
    }
}

// MARK: - Error Handler

/// Centralized error handling with recovery options
///
/// **Features**:
/// - User-friendly error messages
/// - Actionable recovery suggestions
/// - Automatic retry logic
/// - Error logging for debugging
///
/// **Author**: Jordan Koch
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: HomeKitError?
    @Published var showingError: Bool = false

    /// Error log for debugging
    @Published var errorLog: [ErrorLogEntry] = []

    struct ErrorLogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let error: HomeKitError
        let context: String?

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            return formatter.string(from: timestamp)
        }
    }

    private init() {}

    /// Handle an error with optional context
    ///
    /// **Logging**: All errors are logged for debugging
    /// **UI**: Shows error alert to user
    func handle(_ error: HomeKitError, context: String? = nil) {
        // Log error
        let logEntry = ErrorLogEntry(timestamp: Date(), error: error, context: context)
        errorLog.insert(logEntry, at: 0)

        // Limit log size
        if errorLog.count > 50 {
            errorLog = Array(errorLog.prefix(50))
        }

        // Show to user
        currentError = error
        showingError = true

        // Log to console for debugging
        print("❌ HomeKit Error: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
        if let reason = error.failureReason {
            print("   Reason: \(reason)")
        }
        if let suggestion = error.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
    }

    /// Execute a recovery action
    func executeRecovery(_ action: RecoveryAction, for error: HomeKitError, retryHandler: (() -> Void)? = nil) {
        switch action {
        case .retry, .waitAndRetry:
            showingError = false
            retryHandler?()

        case .dismiss:
            showingError = false
            currentError = nil

        case .openHomeApp:
            if let url = URL(string: "com.apple.Home://") {
                // Open Home app (iOS only)
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            showingError = false

        case .openSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #endif
            }
            showingError = false

        case .viewDetails, .checkStatus, .editScene, .checkNetwork, .edit:
            // These actions require navigation or additional context
            // Should be handled by the calling view
            showingError = false
        }
    }

    /// Clear error log
    func clearErrorLog() {
        errorLog.removeAll()
    }
}

// MARK: - Error Alert View

/// Reusable error alert view with recovery actions
///
/// Shows user-friendly error messages with actionable buttons.
///
/// **Usage**:
/// ```swift
/// .sheet(isPresented: $errorHandler.showingError) {
///     ErrorAlertView(error: errorHandler.currentError!, onAction: { action in
///         errorHandler.executeRecovery(action, for: error) {
///             // Retry logic here
///         }
///     })
/// }
/// ```
struct ErrorAlertView: View {
    let error: HomeKitError
    let onAction: (RecoveryAction) -> Void

    var body: some View {
        VStack(spacing: 30) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            // Error Message
            VStack(spacing: 12) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                if let reason = error.failureReason {
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.callout)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 40)

            // Recovery Actions
            VStack(spacing: 12) {
                ForEach(error.recoveryActions, id: \.self) { action in
                    Button(action: {
                        onAction(action)
                    }) {
                        HStack {
                            Image(systemName: action.icon)
                            Text(action.rawValue)
                        }
                        .frame(minWidth: 300)
                        .padding()
                        .background(action == .retry ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(action == .retry ? .white : .primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(40)
        .frame(width: 700, height: 600)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
