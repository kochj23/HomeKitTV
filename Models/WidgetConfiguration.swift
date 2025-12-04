import Foundation

class WidgetConfiguration: ObservableObject {
    static let shared = WidgetConfiguration()
    @Published var widgetSettings: [String: WidgetSetting] = [:]
    
    struct WidgetSetting: Codable {
        var widgetID: String
        var size: WidgetSize
        var refreshInterval: TimeInterval
        var showIcon: Bool
        var customColor: String?
    }
    
    enum WidgetSize: String, Codable {
        case small, medium, large
    }
}