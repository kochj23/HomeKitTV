import Foundation

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    @Published var profiles: [UserProfile] = []
    @Published var currentUser: UserProfile?
    
    struct UserProfile: Identifiable, Codable {
        let id: UUID
        var name: String
        var favoriteDevices: [String]
        var dashboardLayout: [String: Any]?
        var permissions: Permissions
        var theme: String
        
        struct Permissions: Codable {
            var canControlDevices: Bool
            var canCreateScenes: Bool
            var canManageUsers: Bool
            var canViewAnalytics: Bool
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, favoriteDevices, permissions, theme
        }
    }
    
    func switchUser(_ profile: UserProfile) {
        currentUser = profile
    }
    
    func createGuestProfile(name: String) -> UserProfile {
        UserProfile(
            id: UUID(),
            name: name,
            favoriteDevices: [],
            permissions: UserProfile.Permissions(
                canControlDevices: true,
                canCreateScenes: false,
                canManageUsers: false,
                canViewAnalytics: false
            ),
            theme: "default"
        )
    }
}