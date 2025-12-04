import Foundation
import HomeKit
import SwiftUI

/// Selection manager for multi-select operations
///
/// Manages the selection state of accessories across the app and provides
/// bulk action capabilities.
///
/// **Features**:
/// - Multi-select accessories
/// - Bulk on/off operations
/// - Bulk brightness adjustment
/// - Add to scene operations
/// - Room assignment
///
/// **Memory Safety**: Uses weak references and proper cleanup
class SelectionManager: ObservableObject {
    // MARK: - Singleton

    static let shared = SelectionManager()

    // MARK: - Published Properties

    /// Currently selected accessories
    @Published var selectedAccessories: Set<String> = []

    /// Whether selection mode is active
    @Published var isSelectionMode: Bool = false

    /// Status message for bulk operations
    @Published var bulkOperationStatus: String = ""

    // MARK: - Private Properties

    private init() {}

    // MARK: - Selection Management

    /// Toggle selection for an accessory
    func toggleSelection(_ accessory: HMAccessory) {
        let id = accessory.uniqueIdentifier.uuidString
        if selectedAccessories.contains(id) {
            selectedAccessories.remove(id)
        } else {
            selectedAccessories.insert(id)
        }
    }

    /// Check if accessory is selected
    func isSelected(_ accessory: HMAccessory) -> Bool {
        return selectedAccessories.contains(accessory.uniqueIdentifier.uuidString)
    }

    /// Clear all selections
    func clearSelection() {
        selectedAccessories.removeAll()
    }

    /// Select all accessories from list
    func selectAll(_ accessories: [HMAccessory]) {
        selectedAccessories = Set(accessories.map { $0.uniqueIdentifier.uuidString })
    }

    /// Enter selection mode
    func enterSelectionMode() {
        isSelectionMode = true
        clearSelection()
    }

    /// Exit selection mode
    func exitSelectionMode() {
        isSelectionMode = false
        clearSelection()
    }

    // MARK: - Bulk Actions

    /// Get selected accessories from a list
    func getSelectedAccessories(from accessories: [HMAccessory]) -> [HMAccessory] {
        return accessories.filter { selectedAccessories.contains($0.uniqueIdentifier.uuidString) }
    }

    /// Bulk turn on/off selected accessories
    ///
    /// **Memory Safety**: Uses [weak self] in all callbacks
    func bulkPowerToggle(accessories: [HMAccessory], turnOn: Bool, completion: @escaping (Int, Int) -> Void) {
        let selected = getSelectedAccessories(from: accessories)
        guard !selected.isEmpty else {
            completion(0, 0)
            return
        }

        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()

        for accessory in selected {
            guard let service = accessory.services.first(where: { service in
                service.characteristics.contains { $0.characteristicType == HMCharacteristicTypePowerState }
            }),
            let characteristic = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypePowerState
            }) else {
                failureCount += 1
                continue
            }

            group.enter()
            characteristic.writeValue(turnOn) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        successCount += 1
                    } else {
                        failureCount += 1
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            completion(successCount, failureCount)
            self?.bulkOperationStatus = "✓ \(successCount) devices updated, \(failureCount) failed"

            // Clear status after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.bulkOperationStatus = ""
            }
        }
    }

    /// Bulk brightness adjustment for selected lights
    ///
    /// **Memory Safety**: Uses [weak self] in all callbacks
    func bulkBrightnessAdjustment(accessories: [HMAccessory], brightness: Int, completion: @escaping (Int, Int) -> Void) {
        let selected = getSelectedAccessories(from: accessories)
        guard !selected.isEmpty else {
            completion(0, 0)
            return
        }

        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()

        for accessory in selected {
            guard let service = accessory.services.first(where: { service in
                service.characteristics.contains { $0.characteristicType == HMCharacteristicTypeBrightness }
            }),
            let characteristic = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeBrightness
            }) else {
                failureCount += 1
                continue
            }

            group.enter()
            characteristic.writeValue(brightness) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        successCount += 1
                    } else {
                        failureCount += 1
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            completion(successCount, failureCount)
            self?.bulkOperationStatus = "✓ \(successCount) lights adjusted, \(failureCount) failed"

            // Clear status after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.bulkOperationStatus = ""
            }
        }
    }

    /// Bulk room assignment
    ///
    /// **Note**: Not available on tvOS - room assignment APIs are iOS/macOS only
    ///
    /// **Memory Safety**: Uses [weak self] in all callbacks
    #if !os(tvOS)
    func bulkRoomAssignment(accessories: [HMAccessory], room: HMRoom, home: HMHome, completion: @escaping (Int, Int) -> Void) {
        let selected = getSelectedAccessories(from: accessories)
        guard !selected.isEmpty else {
            completion(0, 0)
            return
        }

        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()

        for accessory in selected {
            group.enter()
            home.assignAccessory(accessory, to: room) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        successCount += 1
                    } else {
                        failureCount += 1
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            completion(successCount, failureCount)
            self?.bulkOperationStatus = "✓ \(successCount) devices moved to \(room.name), \(failureCount) failed"

            // Clear status after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.bulkOperationStatus = ""
            }
        }
    }
    #endif
}
