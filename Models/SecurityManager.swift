import Foundation
import HomeKit

// MARK: - Security Manager

/// Manages security features including rate limiting and input validation
///
/// **Security Features**:
/// - Rate limiting to prevent DoS on HomeKit hub
/// - Input validation for scene names and automation rules
/// - Command throttling
/// - Suspicious activity detection
///
/// **Author**: Jordan Koch
class SecurityManager: ObservableObject {
    static let shared = SecurityManager()

    // MARK: - Rate Limiting

    @Published var isRateLimited: Bool = false

    private var commandTimestamps: [Date] = []
    private let maxCommandsPerMinute = 60
    private let maxCommandsPerTenSeconds = 20

    /// Checks if a command can be executed based on rate limits
    ///
    /// **Security**: Prevents DoS attacks on HomeKit hub
    /// **Limits**:
    /// - 60 commands per minute
    /// - 20 commands per 10 seconds (burst protection)
    ///
    /// - Returns: True if command is allowed, false if rate limited
    func canExecuteCommand() -> Bool {
        cleanOldTimestamps()

        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let tenSecondsAgo = now.addingTimeInterval(-10)

        let recentCommands = commandTimestamps.filter { $0 > oneMinuteAgo }
        let burstCommands = commandTimestamps.filter { $0 > tenSecondsAgo }

        // Check minute limit
        if recentCommands.count >= maxCommandsPerMinute {
            isRateLimited = true
            return false
        }

        // Check burst limit
        if burstCommands.count >= maxCommandsPerTenSeconds {
            isRateLimited = true
            return false
        }

        isRateLimited = false
        return true
    }

    /// Records that a command was executed
    func recordCommand() {
        commandTimestamps.append(Date())
        cleanOldTimestamps()
    }

    /// Removes timestamps older than 1 minute
    private func cleanOldTimestamps() {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        commandTimestamps.removeAll { $0 < oneMinuteAgo }
    }

    /// Gets current command rate (commands per minute)
    func getCurrentRate() -> Int {
        cleanOldTimestamps()
        return commandTimestamps.count
    }

    /// Time until rate limit resets
    func timeUntilReset() -> TimeInterval? {
        guard isRateLimited, let oldest = commandTimestamps.first else {
            return nil
        }

        let resetTime = oldest.addingTimeInterval(60)
        return resetTime.timeIntervalSince(Date())
    }

    // MARK: - Input Validation

    /// Validates a scene name
    ///
    /// **Security**: Prevents injection attacks and ensures reasonable names
    ///
    /// - Parameter name: Scene name to validate
    /// - Returns: Validation result with error message if invalid
    func validateSceneName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check length
        guard trimmed.count >= 1 else {
            return ValidationResult(isValid: false, error: "Scene name cannot be empty")
        }

        guard trimmed.count <= 100 else {
            return ValidationResult(isValid: false, error: "Scene name must be 100 characters or less")
        }

        // Check for valid characters
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_.,!?'\"()[]{}"))

        let invalid = trimmed.unicodeScalars.filter { !allowed.contains($0) }
        guard invalid.isEmpty else {
            return ValidationResult(isValid: false, error: "Scene name contains invalid characters: \(String(UnicodeScalarView(invalid)))")
        }

        // Check for suspicious patterns (SQL injection attempts, etc.)
        let suspiciousPatterns = ["--", "/*", "*/", "xp_", "DROP", "SELECT", "INSERT", "DELETE", "UPDATE", "EXEC", "<script"]
        for pattern in suspiciousPatterns {
            if trimmed.lowercased().contains(pattern.lowercased()) {
                return ValidationResult(isValid: false, error: "Scene name contains suspicious content")
            }
        }

        return ValidationResult(isValid: true, error: nil)
    }

    /// Validates an automation name
    func validateAutomationName(_ name: String) -> ValidationResult {
        // Same rules as scene name
        return validateSceneName(name)
    }

    /// Validates a numeric value for characteristics
    ///
    /// **Security**: Ensures values are within acceptable ranges
    ///
    /// - Parameters:
    ///   - value: The value to validate
    ///   - min: Minimum allowed value
    ///   - max: Maximum allowed value
    ///   - characteristic: Name of characteristic for error messages
    /// - Returns: Validation result
    func validateNumericValue(_ value: Any, min: Double, max: Double, characteristic: String) -> ValidationResult {
        guard let numericValue = value as? Double else {
            return ValidationResult(isValid: false, error: "\(characteristic) must be a number")
        }

        guard numericValue >= min && numericValue <= max else {
            return ValidationResult(isValid: false, error: "\(characteristic) must be between \(Int(min)) and \(Int(max))")
        }

        return ValidationResult(isValid: true, error: nil)
    }

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let error: String?
    }

    // MARK: - Suspicious Activity Detection

    private var failedCommandCount: Int = 0
    private var lastFailureTime: Date?

    /// Records a failed command for suspicious activity tracking
    func recordFailedCommand() {
        failedCommandCount += 1
        lastFailureTime = Date()

        // Reset counter after 1 hour
        if let lastFailure = lastFailureTime,
           Date().timeIntervalSince(lastFailure) > 3600 {
            failedCommandCount = 0
        }
    }

    /// Checks if there's suspicious activity (many failed commands)
    var hasSuspiciousActivity: Bool {
        return failedCommandCount > 10
    }

    // MARK: - Persistence

    private func saveQueue() {
        if let encoded = try? JSONEncoder().encode(queuedCommands) {
            UserDefaults.standard.set(encoded, forKey: "offlineCommandQueue")
        }
    }

    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: "offlineCommandQueue"),
           let commands = try? JSONDecoder().decode([PendingCommand].self, from: data) {
            queuedCommands = commands
        }
    }

    private func saveCachedState() {
        // Implementation handled in OfflineModeManager
    }

    private func loadCachedState() {
        loadQueue()
    }
}

// MARK: - Command Type Extensions

extension OfflineModeManager {
    /// Clears the command queue
    func clearQueue() {
        queuedCommands.removeAll()
        saveQueue()
    }

    /// Removes commands older than specified age
    func removeStaleCommands(olderThan age: TimeInterval) {
        queuedCommands.removeAll { $0.age > age }
        saveQueue()
    }
}
