import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var notifications: [HomeNotification] = []
    
    struct HomeNotification: Identifiable {
        let id: UUID
        let title: String
        let message: String
        let timestamp: Date
        let priority: Priority
        
        enum Priority {
            case low, medium, high, critical
        }
    }
    
    func sendNotification(title: String, message: String, priority: HomeNotification.Priority) {
        let notification = HomeNotification(
            id: UUID(),
            title: title,
            message: message,
            timestamp: Date(),
            priority: priority
        )
        notifications.insert(notification, at: 0)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}