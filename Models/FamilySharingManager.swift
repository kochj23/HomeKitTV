import Foundation

class FamilySharingManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = FamilySharingManager()
    @Published var familyMembers: [FamilyMember] = []
    @Published var sharedAutomations: [UUID] = []
    
    struct FamilyMember: Identifiable, Codable {
        let id: UUID
        var name: String
        var role: Role
        var permissions: Permissions
        var favoriteDevices: [String]
        var restrictedDevices: [String]
        var schedule: AccessSchedule?
        
        enum Role: String, Codable {
            case admin, parent, child, guest
        }
        
        struct Permissions: Codable {
            var canControlAll: Bool
            var canCreateAutomations: Bool
            var canManageUsers: Bool
            var canViewAnalytics: Bool
            var canAccessSecuritySystem: Bool
        }
        
        struct AccessSchedule: Codable {
            var allowedHours: [Int]  // 0-23
            var allowedDays: [Int]   // 1-7 (1=Monday)
        }
    }
    
    func addFamilyMember(name: String, role: FamilyMember.Role) {
        let permissions: FamilyMember.Permissions
        
        switch role {
        case .admin:
            permissions = FamilyMember.Permissions(
                canControlAll: true,
                canCreateAutomations: true,
                canManageUsers: true,
                canViewAnalytics: true,
                canAccessSecuritySystem: true
            )
        case .parent:
            permissions = FamilyMember.Permissions(
                canControlAll: true,
                canCreateAutomations: true,
                canManageUsers: false,
                canViewAnalytics: true,
                canAccessSecuritySystem: true
            )
        case .child:
            permissions = FamilyMember.Permissions(
                canControlAll: false,
                canCreateAutomations: false,
                canManageUsers: false,
                canViewAnalytics: false,
                canAccessSecuritySystem: false
            )
        case .guest:
            permissions = FamilyMember.Permissions(
                canControlAll: false,
                canCreateAutomations: false,
                canManageUsers: false,
                canViewAnalytics: false,
                canAccessSecuritySystem: false
            )
        }
        
        let member = FamilyMember(
            id: UUID(),
            name: name,
            role: role,
            permissions: permissions,
            favoriteDevices: [],
            restrictedDevices: []
        )
        
        familyMembers.append(member)
    }
    
    func setParentalControls(for member: FamilyMember, restrictions: [String]) {
        if let index = familyMembers.firstIndex(where: { $0.id == member.id }) {
            familyMembers[index].restrictedDevices = restrictions
        }
    }
}
