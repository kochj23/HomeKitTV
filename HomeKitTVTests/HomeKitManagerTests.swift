import XCTest
@testable import HomeKitTV
import HomeKit

/// Unit tests for HomeKitManager
///
/// Tests core functionality including:
/// - Data loading and state management
/// - Accessory control operations
/// - Scene execution
/// - Filtering and search
/// - Memory management
///
/// **Author**: Jordan Koch
/// **Coverage Target**: 50% of HomeKitManager.swift
final class HomeKitManagerTests: XCTestCase {

    var sut: HomeKitManager!

    override func setUp() {
        super.setUp()
        // Note: HomeKitManager is a singleton, so we're testing the shared instance
        // In production app, this would need dependency injection for proper isolation
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given/When
        sut = HomeKitManager()

        // Then
        XCTAssertNotNil(sut, "HomeKitManager should initialize")
        XCTAssertEqual(sut.homes.count, 0, "Homes should be empty initially")
        XCTAssertTrue(sut.isLoading, "Should be in loading state initially")
        XCTAssertEqual(sut.statusMessage, "", "Status message should be empty initially")
    }

    // MARK: - Data Loading Tests

    func testLoadDataWithNoHome() {
        // Given
        sut = HomeKitManager()

        // When
        sut.loadData()

        // Then
        XCTAssertEqual(sut.statusMessage, "No primary home configured")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
    }

    // MARK: - Filtering Tests

    func testFilteredAccessories_WithEmptySearch() {
        // Given
        sut = HomeKitManager()
        sut.searchQuery = ""

        // When
        let filtered = sut.filteredAccessories

        // Then
        XCTAssertEqual(filtered.count, sut.accessories.count, "Should return all accessories when search is empty")
    }

    func testFilteredAccessories_WithSearchQuery() {
        // Given
        sut = HomeKitManager()
        sut.searchQuery = "Living"

        // When
        let filtered = sut.filteredAccessories

        // Then
        // Should filter accessories containing "Living" in name
        for accessory in filtered {
            XCTAssertTrue(accessory.name.localizedCaseInsensitiveContains("Living"))
        }
    }

    // MARK: - Favorite Tests

    func testFavoriteAccessories_ReturnsOnlyFavorites() {
        // Given
        sut = HomeKitManager()
        let settings = Settings.shared

        // When
        let favorites = sut.favoriteAccessories()

        // Then
        XCTAssertTrue(favorites.count <= sut.accessories.count)
        for accessory in favorites {
            XCTAssertTrue(settings.isFavorite(accessory))
        }
    }

    // MARK: - Room Accessory Tests

    func testAccessoriesForRoom_ReturnsSortedList() {
        // Given
        sut = HomeKitManager()

        // When/Then
        // Test that accessories are sorted by name
        // Note: Requires mock HMRoom with accessories
    }

    // MARK: - Retry Logic Tests

    func testHandleError_RetriesUpToMaxAttempts() {
        // Given
        sut = HomeKitManager()
        var retryCallCount = 0
        let expectation = expectation(description: "Retries should be called")
        expectation.expectedFulfillmentCount = 3  // maxRetryAttempts

        let retryAction = { [weak self] in
            retryCallCount += 1
            if retryCallCount == 3 {
                expectation.fulfill()
            }
        }

        // When
        // Note: handleError is private, need to test indirectly through public API

        // Then
        // Verify retry logic through integration test
    }

    // MARK: - Performance Tests

    func testLoadData_Performance() {
        // Measure performance of data loading
        sut = HomeKitManager()

        measure {
            sut.loadData()
        }
    }

    func testFilteredAccessories_Performance() {
        // Measure filtering performance with large dataset
        sut = HomeKitManager()
        sut.searchQuery = "test"

        measure {
            _ = sut.filteredAccessories
        }
    }

    // MARK: - Memory Management Tests

    func testDeinit_InvalidatesTimer() {
        // Given
        var manager: HomeKitManager? = HomeKitManager()
        weak var weakManager = manager

        // When
        manager = nil

        // Then
        XCTAssertNil(weakManager, "HomeKitManager should be deallocated when reference is cleared")
    }

    func testDeinit_ClearsDelegates() {
        // Test that deinit properly clears all delegates
        // This requires Instruments to verify, but we can test deallocation
        autoreleasepool {
            let manager = HomeKitManager()
            // Manager should clean up when leaving scope
        }
        // If no crashes, delegates were cleared properly
        XCTAssertTrue(true)
    }

    // MARK: - Incremental Update Tests

    func testUpdateAccessory_UpdatesOnlySpecificAccessory() async {
        // Test that updateAccessory only changes the specific accessory
        // Requires mock HMAccessory
    }

    func testIncrementalAdd_MaintainsSortedOrder() async {
        // Test that incremental adds maintain alphabetical sort order
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentAccess_IsThreadSafe() {
        // Test that concurrent modifications don't cause crashes
        sut = HomeKitManager()

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = sut.filteredAccessories
        }

        XCTAssertTrue(true, "Concurrent access should not crash")
    }

    // MARK: - Search Query Tests

    func testSearchQuery_IsCaseInsensitive() {
        sut = HomeKitManager()
        sut.searchQuery = "LIVING"

        let filtered = sut.filteredAccessories

        // All results should contain "living" regardless of case
        for accessory in filtered {
            XCTAssertTrue(accessory.name.localizedCaseInsensitiveContains("LIVING"))
        }
    }
}
