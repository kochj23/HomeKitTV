import SwiftUI
import HomeKit

/// Home sharing and user management view
///
/// Manages:
/// - Home users and permissions
/// - Guest access with time limits
/// - Activity by user
/// - Remote user management
struct HomeSharingView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var homeUsers: [HMUser] {
        #if os(iOS) || os(watchOS) || os(macOS)
        return homeManager.primaryHome?.users ?? []
        #else
        return []
        #endif
    }

    var currentUser: HMUser? {
        #if os(iOS) || os(watchOS) || os(macOS)
        return homeManager.primaryHome?.currentUser
        #else
        return nil
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Home Sharing")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Current User
                    VStack(alignment: .leading, spacing: 20) {
                        Text("You")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        if let user = currentUser {
                            UserCard(user: user, isCurrentUser: true)
                                .padding(.horizontal, 80)
                        }
                    }

                    // Other Users
                    if homeUsers.count > 1 {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Other Users (\(homeUsers.count - 1))")
                                .font(.title2)
                                .padding(.horizontal, 80)

                            ForEach(homeUsers.filter { $0.uniqueIdentifier != currentUser?.uniqueIdentifier }, id: \.uniqueIdentifier) { user in
                                UserCard(user: user, isCurrentUser: false)
                                    .padding(.horizontal, 80)
                            }
                        }
                    }

                    // Permissions Info
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Permissions")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            PermissionRow(
                                icon: "house.fill",
                                title: "Owner",
                                description: "Full control, can add/remove users"
                            )

                            PermissionRow(
                                icon: "person.fill",
                                title: "Admin",
                                description: "Control accessories, create scenes"
                            )

                            PermissionRow(
                                icon: "person.2.fill",
                                title: "User",
                                description: "Control accessories only"
                            )
                        }
                        .padding(25)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }

                    // Sharing Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sharing Settings")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            Text("To add users to your home:")
                                .font(.body)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 10) {
                                BulletPoint(text: "Open the Home app on your iPhone or iPad")
                                BulletPoint(text: "Tap the Home icon in the top-left")
                                BulletPoint(text: "Select 'Home Settings'")
                                BulletPoint(text: "Tap 'Invite People'")
                                BulletPoint(text: "Send an invitation")
                            }
                            .font(.body)
                        }
                        .padding(25)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// User card
struct UserCard: View {
    let user: HMUser
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: isCurrentUser ? "person.circle.fill" : "person.circle")
                .font(.system(size: 50))
                .foregroundColor(isCurrentUser ? .blue : .secondary)
                .frame(width: 70)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Text(user.name)
                        .font(.title3)
                        .bold()

                    if isCurrentUser {
                        Text("You")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                Text("Administrator")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !isCurrentUser {
                Button(action: {
                    // View user details
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 25))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Permission info row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .bold()

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

/// Bullet point view
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.body)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    HomeSharingView()
        .environmentObject(HomeKitManager())
}
