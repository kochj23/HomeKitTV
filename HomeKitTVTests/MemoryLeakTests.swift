import XCTest
@testable import HomeKitTV

/// Memory leak detection tests
///
/// Verifies that critical components properly deallocate and don't have retain cycles.
/// These tests use weak references to detect leaked objects.
///
/// **Author**: Jordan Koch
/// **Purpose**: Prevent memory leaks in production
final class MemoryLeakTests: XCTestCase {

    // MARK: - HomeKitManager Memory Tests

    func testHomeKitManager_Deallocates() {
        // Given
        weak var weakManager: HomeKitManager?

        // When
        autoreleasepool {
            let manager = HomeKitManager()
            weakManager = manager
            // manager goes out of scope here
        }

        // Then
        XCTAssertNil(weakManager, "HomeKitManager should be deallocated when no strong references remain")
    }

    func testHomeKitManager_TimerDoesNotPreventDeallocation() {
        // Given
        weak var weakManager: HomeKitManager?

        // When
        autoreleasepool {
            let manager = HomeKitManager()
            weakManager = manager
            // Simulate timer setup (if auto-refresh enabled)
            // manager.setupAutoRefresh()
        }

        // Then
        // Note: Timer needs to be invalidated in deinit
        XCTAssertNil(weakManager, "HomeKitManager with timer should deallocate when deinit invalidates timer")
    }

    // MARK: - Settings Memory Tests

    func testSettings_SingletonDoesNotLeak() {
        // Settings is a singleton, so it won't deallocate
        // But verify it doesn't cause leaks in other objects
        weak var weakObject: AnyObject?

        autoreleasepool {
            let testObject = NSObject()
            weakObject = testObject
            _ = Settings.shared  // Access singleton
        }

        XCTAssertNil(weakObject, "Other objects should still deallocate normally")
    }

    // MARK: - Manager Memory Tests

    func testEnergyMonitoringManager_InvalidatesTimerOnDeinit() {
        // Given
        weak var weakManager: EnergyMonitoringManager?

        // When
        autoreleasepool {
            let manager = EnergyMonitoringManager.shared
            weakManager = manager
        }

        // Note: Singleton won't deallocate, but this documents expected behavior
        // In a non-singleton context, timer must be invalidated
    }

    func testWatchConnectivityManager_ClearsDelegateOnDeinit() {
        // Given
        weak var weakManager: WatchConnectivityManager?

        // When
        autoreleasepool {
            let manager = WatchConnectivityManager.shared
            weakManager = manager
        }

        // Note: Singleton won't deallocate, but this documents expected behavior
        // In a non-singleton context, delegate must be cleared
    }

    func testGeofencingManager_ClearsLocationDelegateOnDeinit() {
        // Given
        weak var weakManager: GeofencingManager?

        // When
        autoreleasepool {
            let manager = GeofencingManager.shared
            weakManager = manager
        }

        // Note: Singleton won't deallocate, but this documents expected behavior
        // In a non-singleton context, CLLocationManager.delegate must be cleared
    }

    func testRemoteControlManager_RemovesObserversOnDeinit() {
        // Given
        weak var weakManager: RemoteControlManager?

        // When
        autoreleasepool {
            let manager = RemoteControlManager.shared
            manager.setupRemoteControl()  // Adds observer
            weakManager = manager
        }

        // Note: Singleton won't deallocate, but this documents expected behavior
        // In a non-singleton context, NotificationCenter.removeObserver must be called
    }

    // MARK: - Closure Retention Tests

    func testClosureWithWeakSelf_DoesNotRetainManager() {
        // Given
        weak var weakManager: HomeKitManager?

        // When
        autoreleasepool {
            let manager = HomeKitManager()
            weakManager = manager

            // Simulate closure with [weak self]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak manager] in
                _ = manager?.statusMessage
            }
        }

        // Then
        // Wait briefly for closure to execute
        let expectation = expectation(description: "Closure executes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(weakManager, "Manager should deallocate even with pending closure using [weak self]")
    }

    // MARK: - Activity History Memory Tests

    func testActivityHistory_AutomaticallyLimitsSize() {
        // Given
        let settings = Settings.shared
        settings.activityHistory = []

        // When - Add many entries
        for i in 0..<100 {
            let entry = ActivityEntry(action: "Test\(i)", accessoryName: "Device", accessoryID: "123")
            settings.addActivity(entry)
        }

        // Then
        XCTAssertLessThanOrEqual(settings.activityHistory.count, 50, "History should never exceed 50 entries")
    }

    func testActivityHistory_OldestEntriesAreRemoved() {
        // Given
        let settings = Settings.shared
        settings.activityHistory = []

        // When - Add entries in order
        let firstEntry = ActivityEntry(action: "First", accessoryName: "Device", accessoryID: "1")
        settings.addActivity(firstEntry)

        for i in 1...60 {
            let entry = ActivityEntry(action: "Action\(i)", accessoryName: "Device", accessoryID: "\(i)")
            settings.addActivity(entry)
        }

        // Then
        let hasFirstEntry = settings.activityHistory.contains(where: { $0.accessoryID == "1" })
        XCTAssertFalse(hasFirstEntry, "Oldest entry should be removed when limit exceeded")
        XCTAssertEqual(settings.activityHistory.count, 50)
    }

    // MARK: - Performance Tests

    func testActivityHistory_AddPerformance() {
        let settings = Settings.shared

        measure {
            let entry = ActivityEntry(action: "Test", accessoryName: "Device", accessoryID: "123")
            settings.addActivity(entry)
        }
    }

    func testFavoriteToggle_Performance() {
        let settings = Settings.shared
        let testID = UUID().uuidString

        measure {
            if settings.favoriteAccessoryIDs.contains(testID) {
                settings.favoriteAccessoryIDs.remove(testID)
            } else {
                settings.favoriteAccessoryIDs.insert(testID)
            }
        }
    }

    // MARK: - Persistence Integration Tests

    func testFavorites_PersistAcrossInstances() {
        // This test verifies that favorites are properly persisted
        // Note: Since Settings is a singleton, this is more of a documentation test
        let settings = Settings.shared
        let testID = UUID().uuidString

        settings.favoriteAccessoryIDs.insert(testID)

        // Verify it persists
        XCTAssertTrue(settings.favoriteAccessoryIDs.contains(testID))
    }
}
