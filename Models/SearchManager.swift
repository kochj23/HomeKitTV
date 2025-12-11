import Foundation
import HomeKit

class SearchManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = SearchManager()
    @Published var searchResults: [SearchResult] = []
    @Published var recentSearches: [String] = []
    
    struct SearchResult: Identifiable {
        let id: UUID
        let type: ResultType
        let name: String
        let subtitle: String?
        let matchedObject: Any
        
        enum ResultType {
            case device, scene, room, automation
        }
    }
    
    func search(_ query: String, in accessories: [HMAccessory], scenes: [HMActionSet], rooms: [HMRoom]) {
        searchResults.removeAll()
        let lowercaseQuery = query.lowercased()
        
        // Search accessories
        for accessory in accessories where accessory.name.lowercased().contains(lowercaseQuery) {
            searchResults.append(SearchResult(
                id: UUID(),
                type: .device,
                name: accessory.name,
                subtitle: accessory.room?.name,
                matchedObject: accessory
            ))
        }
        
        // Search scenes
        for scene in scenes where scene.name.lowercased().contains(lowercaseQuery) {
            searchResults.append(SearchResult(
                id: UUID(),
                type: .scene,
                name: scene.name,
                subtitle: "Scene",
                matchedObject: scene
            ))
        }
        
        // Add to recent searches
        if !recentSearches.contains(query) {
            recentSearches.insert(query, at: 0)
            if recentSearches.count > 10 {
                recentSearches.removeLast()
            }
        }
    }
}
