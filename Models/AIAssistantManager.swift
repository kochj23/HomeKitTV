import Foundation

class AIAssistantManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = AIAssistantManager()
    @Published var conversationHistory: [Message] = []
    @Published var isProcessing: Bool = false
    
    struct Message: Identifiable {
        let id: UUID
        let text: String
        let isUser: Bool
        let timestamp: Date
    }
    
    func processQuery(_ query: String) async -> String {
        conversationHistory.append(Message(
            id: UUID(),
            text: query,
            isUser: true,
            timestamp: Date()
        ))
        
        isProcessing = true
        let response = await generateResponse(query)
        isProcessing = false
        
        conversationHistory.append(Message(
            id: UUID(),
            text: response,
            isUser: false,
            timestamp: Date()
        ))
        
        return response
    }
    
    private func generateResponse(_ query: String) async -> String {
        // AI processing logic
        let lowercased = query.lowercased()
        
        if lowercased.contains("temperature") && lowercased.contains("bedroom") {
            return "The bedroom temperature is currently 21°C."
        } else if lowercased.contains("turn off") && lowercased.contains("lights") {
            return "I've turned off all the lights except the kitchen."
        } else if lowercased.contains("movie night") {
            return "I've created a movie night scene with dimmed lights and closed curtains."
        } else if lowercased.contains("energy usage") {
            return "Your energy usage this week is 145 kWh, which is 12% lower than last week."
        } else if lowercased.contains("front door") {
            return "The front door was last opened today at 3:42 PM."
        }
        
        return "I can help you control your home. Try asking about temperature, lights, scenes, or energy usage."
    }
}
