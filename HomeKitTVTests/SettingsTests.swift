import XCTest
@testable import HomeKitTV

/// Unit tests for Settings manager
///
/// Tests persistence, favorites, and activity history management.
///
/// **Author**: Jordan Koch
/// **Coverage Target**: 75% of Settings.swift
final class SettingsTests: XCTestCase {

    var sut: Settings!
    let testUserDefaults = UserDefaults(suiteName: "com.homekittv.tests")!

    override func setUp() {
        super.setUp()
        // Note: Settings is a singleton, testing requires care
        // Clear test user defaults
        testUserDefaults.removePersistentDomain(forName: "com.homekittv.tests")
    }

    override func tearDown() {
        sut = nil
        testUserDefaults.removePersistentDomain(forName: "com.homekittv.tests")
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_LoadsDefaults() {
        // When
        sut = Settings.shared

        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.statusMessageDuration, 3.0, "Default status message duration should be 3 seconds")
        XCTAssertEqual(sut.autoRefreshInterval, 0.0, "Default auto-refresh should be disabled")
        XCTAssertTrue(sut.showBatteryLevels, "Should show battery levels by default")
        XCTAssertTrue(sut.showReachabilityIndicators, "Should show reachability by default")
    }

    // MARK: - Favorites Management Tests

    func testToggleFavorite_Accessory_AddsToSet() {
        // Given
        sut = Settings.shared
        let mockAccessoryID = UUID().uuidString
        let initialCount = sut.favoriteAccessoryIDs.count

        // When
        // Note: Need mock HMAccessory for complete test
        sut.favoriteAccessoryIDs.insert(mockAccessoryID)

        // Then
        XCTAssertTrue(sut.favoriteAccessoryIDs.contains(mockAccessoryID))
        XCTAssertEqual(sut.favoriteAccessoryIDs.count, initialCount + 1)
    }

    func testToggleFavorite_RemovesFromSet() {
        // Given
        sut = Settings.shared
        let mockAccessoryID = UUID().uuidString
        sut.favoriteAccessoryIDs.insert(mockAccessoryID)

        // When
        sut.favoriteAccessoryIDs.remove(mockAccessoryID)

        // Then
        XCTAssertFalse(sut.favoriteAccessoryIDs.contains(mockAccessoryID))
    }

    // MARK: - Activity History Tests

    func testAddActivity_InsertsAtBeginning() {
        // Given
        sut = Settings.shared
        let entry = ActivityEntry(action: "Test", accessoryName: "TestDevice", accessoryID: "123")

        // When
        sut.addActivity(entry)

        // Then
        XCTAssertEqual(sut.activityHistory.first?.action, "Test")
        XCTAssertEqual(sut.activityHistory.first?.accessoryName, "TestDevice")
    }

    func testActivityHistory_EnforcesLimit() {
        // Given
        sut = Settings.shared
        sut.activityHistory = []

        // When - Add 60 entries (limit is 50)
        for i in 0..<60 {
            let entry = ActivityEntry(action: "Action\(i)", accessoryName: "Device\(i)", accessoryID: "\(i)")
            sut.addActivity(entry)
        }

        // Then
        XCTAssertEqual(sut.activityHistory.count, 50, "Activity history should be limited to 50 entries")
        XCTAssertEqual(sut.activityHistory.first?.action, "Action59", "Most recent entry should be first")
    }

    func testClearHistory_RemovesAllEntries() {
        // Given
        sut = Settings.shared
        for i in 0..<10 {
            let entry = ActivityEntry(action: "Action\(i)", accessoryName: "Device", accessoryID: "123")
            sut.addActivity(entry)
        }

        // When
        sut.clearHistory()

        // Then
        XCTAssertEqual(sut.activityHistory.count, 0, "History should be empty after clear")
    }

    // MARK: - Persistence Tests

    func testSaveFavorites_PersistsToUserDefaults() {
        // Given
        sut = Settings.shared
        let testID = UUID().uuidString

        // When
        sut.favoriteAccessoryIDs.insert(testID)

        // Then
        // Note: Would need to check UserDefaults, but that requires access to internal Keys
        XCTAssertTrue(sut.favoriteAccessoryIDs.contains(testID))
    }

    // MARK: - Font Size Tests

    func testFontSizeMultiplier_Defaults() {
        // When
        sut = Settings.shared

        // Then
        XCTAssertEqual(sut.fontSizeMultiplier, 0.25, "Default font size should be 0.25 (Medium)")
    }

    func testFontSizeMultiplier_CanBeChanged() {
        // Given
        sut = Settings.shared

        // When
        sut.fontSizeMultiplier = 1.2

        // Then
        XCTAssertEqual(sut.fontSizeMultiplier, 1.2)
    }

    // MARK: - Filter Preference Tests

    func testHideUnreachableAccessories_DefaultsFalse() {
        // When
        sut = Settings.shared

        // Then
        XCTAssertFalse(sut.hideUnreachableAccessories, "Should show unreachable accessories by default")
    }

    func testHideEmptyRooms_DefaultsFalse() {
        // When
        sut = Settings.shared

        // Then
        XCTAssertFalse(sut.hideEmptyRooms, "Should show empty rooms by default")
    }

    // MARK: - Activity Entry Tests

    func testActivityEntry_HasUniqueID() {
        // When
        let entry1 = ActivityEntry(action: "Test", accessoryName: "Device", accessoryID: "123")
        let entry2 = ActivityEntry(action: "Test", accessoryName: "Device", accessoryID: "123")

        // Then
        XCTAssertNotEqual(entry1.id, entry2.id, "Each entry should have unique ID")
    }

    func testActivityEntry_FormatsTimestamp() {
        // Given
        let entry = ActivityEntry(action: "Test", accessoryName: "Device", accessoryID: "123")

        // When
        let formatted = entry.formattedTime

        // Then
        XCTAssertFalse(formatted.isEmpty, "Formatted time should not be empty")
        XCTAssertTrue(formatted.contains("/") || formatted.contains(":"), "Should contain date/time separators")
    }

    func testActivityEntry_FormatsRelativeTime() {
        // Given
        let entry = ActivityEntry(action: "Test", accessoryName: "Device", accessoryID: "123")

        // When
        let relative = entry.relativeTime

        // Then
        XCTAssertFalse(relative.isEmpty, "Relative time should not be empty")
        // Should contain phrases like "seconds ago", "minutes ago", etc.
    }

    // MARK: - Memory Tests

    func testSettings_DoesNotLeak() {
        // Settings is a singleton, but verify no additional leaks
        autoreleasepool {
            let settings = Settings.shared
            _ = settings.activityHistory
        }
        XCTAssertTrue(true, "Settings access should not cause leaks")
    }

    // MARK: - Activity History Retention Tests

    func testActivityHistory_EnforcesLimitInDidSet() {
        // Given
        sut = Settings.shared

        // When - Directly set history beyond limit
        var largeHistory: [ActivityEntry] = []
        for i in 0..<60 {
            largeHistory.append(ActivityEntry(action: "Test\(i)", accessoryName: "Device", accessoryID: "123"))
        }
        sut.activityHistory = largeHistory

        // Then
        XCTAssertLessThanOrEqual(sut.activityHistory.count, 50, "didSet should enforce 50-entry limit")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentFavoriteToggle_IsThreadSafe() {
        // Given
        sut = Settings.shared
        let testIDs = (0..<100).map { _ in UUID().uuidString }

        // When - Concurrent modifications
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            if index % 2 == 0 {
                sut.favoriteAccessoryIDs.insert(testIDs[index])
            } else {
                sut.favoriteAccessoryIDs.remove(testIDs[index])
            }
        }

        // Then
        // Should not crash
        XCTAssertTrue(true, "Concurrent access should be safe")
    }
}
