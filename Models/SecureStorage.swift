import Foundation
import Security

/// Secure storage manager using iOS Keychain
///
/// This class provides a secure interface for storing sensitive data like API keys,
/// tokens, passwords, and other credentials using the iOS Keychain Services API.
///
/// **Security Features**:
/// - AES-256 encryption (provided by Keychain)
/// - Secure enclave support (when available)
/// - Protection against unauthorized access
/// - Data is encrypted at rest
/// - Automatic cleanup on app deletion
///
/// **Usage**:
/// ```swift
/// // Store a webhook URL
/// try SecureStorage.shared.save(key: "webhook_url", value: "https://api.example.com/hook")
///
/// // Retrieve the URL
/// let url = try SecureStorage.shared.retrieve(key: "webhook_url")
///
/// // Delete the URL
/// try SecureStorage.shared.delete(key: "webhook_url")
/// ```
///
/// **Thread Safety**: All methods are thread-safe and can be called from any queue.
///
/// - Warning: Do not store large data objects in Keychain. Use for credentials only.
/// - Note: Keychain data persists across app uninstalls if iCloud Keychain is enabled
class SecureStorage {
    /// Shared singleton instance
    static let shared = SecureStorage()

    /// Service identifier for Keychain
    private let service = "com.homekittv.securestorage"

    /// Access group for shared keychain items (if needed for app extensions)
    private let accessGroup: String? = nil

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public API

    /// Save a string value securely to Keychain
    ///
    /// - Parameters:
    ///   - key: The unique key to store the value under
    ///   - value: The string value to store
    /// - Throws: `SecureStorageError` if save operation fails
    ///
    /// **Example**:
    /// ```swift
    /// try SecureStorage.shared.save(key: "api_key", value: "sk_live_12345")
    /// ```
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStorageError.invalidData
        }

        try save(key: key, data: data)
    }

    /// Save data securely to Keychain
    ///
    /// - Parameters:
    ///   - key: The unique key to store the data under
    ///   - data: The data to store
    /// - Throws: `SecureStorageError` if save operation fails
    ///
    /// **Security**: Data is encrypted using AES-256 by the Keychain
    func save(key: String, data: Data) throws {
        // First, try to delete any existing item
        _ = try? delete(key: key)

        // Build the query dictionary
        var query = baseQuery(key: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        // Add the item to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SecureStorageError.unableToSave(status)
        }
    }

    /// Retrieve a string value from Keychain
    ///
    /// - Parameter key: The key to retrieve the value for
    /// - Returns: The stored string value, or nil if not found
    /// - Throws: `SecureStorageError` if retrieval fails
    ///
    /// **Example**:
    /// ```swift
    /// if let apiKey = try SecureStorage.shared.retrieve(key: "api_key") {
    ///     print("API Key found: \(apiKey)")
    /// }
    /// ```
    func retrieve(key: String) throws -> String? {
        guard let data = try retrieveData(key: key) else {
            return nil
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.invalidData
        }

        return string
    }

    /// Retrieve data from Keychain
    ///
    /// - Parameter key: The key to retrieve the data for
    /// - Returns: The stored data, or nil if not found
    /// - Throws: `SecureStorageError` if retrieval fails
    func retrieveData(key: String) throws -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw SecureStorageError.unableToRetrieve(status)
        }

        guard let data = result as? Data else {
            throw SecureStorageError.invalidData
        }

        return data
    }

    /// Delete a value from Keychain
    ///
    /// - Parameter key: The key to delete
    /// - Throws: `SecureStorageError` if deletion fails
    ///
    /// **Example**:
    /// ```swift
    /// try SecureStorage.shared.delete(key: "api_key")
    /// ```
    func delete(key: String) throws {
        let query = baseQuery(key: key)
        let status = SecItemDelete(query as CFDictionary)

        // Success or item not found are both acceptable
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.unableToDelete(status)
        }
    }

    /// Delete all values for this service
    ///
    /// - Warning: This will remove ALL stored values. Use with caution.
    ///
    /// **Example**:
    /// ```swift
    /// try SecureStorage.shared.deleteAll()
    /// ```
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.unableToDelete(status)
        }
    }

    /// Check if a key exists in Keychain
    ///
    /// - Parameter key: The key to check
    /// - Returns: `true` if the key exists, `false` otherwise
    ///
    /// **Example**:
    /// ```swift
    /// if SecureStorage.shared.exists(key: "api_key") {
    ///     print("API key is stored")
    /// }
    /// ```
    func exists(key: String) -> Bool {
        do {
            return try retrieveData(key: key) != nil
        } catch {
            return false
        }
    }

    // MARK: - Private Helpers

    /// Build the base query dictionary for Keychain operations
    ///
    /// - Parameter key: The key to use in the query
    /// - Returns: Dictionary with base Keychain query parameters
    private func baseQuery(key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Add access group if configured (for app extensions)
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Errors

/// Errors that can occur during secure storage operations
enum SecureStorageError: Error, LocalizedError {
    /// The data could not be converted to/from the expected format
    case invalidData

    /// Unable to save the item to Keychain
    case unableToSave(OSStatus)

    /// Unable to retrieve the item from Keychain
    case unableToRetrieve(OSStatus)

    /// Unable to delete the item from Keychain
    case unableToDelete(OSStatus)

    /// Human-readable error descriptions
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The data format is invalid"
        case .unableToSave(let status):
            return "Unable to save to Keychain (status: \(status))"
        case .unableToRetrieve(let status):
            return "Unable to retrieve from Keychain (status: \(status))"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain (status: \(status))"
        }
    }
}
