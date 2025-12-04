import Foundation
import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: Theme = .default
    
    struct Theme: Codable {
        var name: String
        var primaryColor: String
        var secondaryColor: String
        var backgroundColor: String
        var accentColor: String
        var cardStyle: CardStyle
        
        enum CardStyle: String, Codable {
            case rounded, square, circular
        }
        
        static let `default` = Theme(
            name: "Default",
            primaryColor: "blue",
            secondaryColor: "gray",
            backgroundColor: "black",
            accentColor: "blue",
            cardStyle: .rounded
        )
    }
    
    func applyTheme(_ theme: Theme) {
        currentTheme = theme
    }
    
    var themes: [Theme] {
        [
            .default,
            Theme(name: "Dark", primaryColor: "purple", secondaryColor: "gray", backgroundColor: "black", accentColor: "purple", cardStyle: .rounded),
            Theme(name: "Light", primaryColor: "blue", secondaryColor: "gray", backgroundColor: "white", accentColor: "blue", cardStyle: .square),
            Theme(name: "Ocean", primaryColor: "cyan", secondaryColor: "teal", backgroundColor: "navy", accentColor: "cyan", cardStyle: .circular)
        ]
    }
}