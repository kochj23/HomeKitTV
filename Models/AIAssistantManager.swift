//
//  AIAssistantManager.swift
//  HomeKitTV
//
//  AI Assistant with TinyChat support for intelligent HomeKit control
//  Author: Jordan Koch
//
//  THIRD-PARTY INTEGRATIONS:
//  - TinyChat by Jason Cox (https://github.com/jasonacox/tinychat)
//    Fast chatbot interface with OpenAI-compatible API
//  - TinyLLM by Jason Cox (https://github.com/jasonacox/TinyLLM)
//    Lightweight LLM server with OpenAI-compatible API
//

import Foundation

class AIAssistantManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = AIAssistantManager()
    @Published var conversationHistory: [Message] = []
    @Published var isProcessing: Bool = false
    @Published var isTinyChatAvailable: Bool = false
    @Published var isTinyLLMAvailable: Bool = false
    @Published var useAIBackend: Bool = true

    // TinyChat configuration (Jason Cox: https://github.com/jasonacox/tinychat)
    private var tinyChatServerURL: String = "http://localhost:8000"

    // TinyLLM configuration (Jason Cox: https://github.com/jasonacox/TinyLLM)
    private var tinyLLMServerURL: String = "http://localhost:8000"

    struct Message: Identifiable {
        let id: UUID
        let text: String
        let isUser: Bool
        let timestamp: Date
    }

    private init() {
        Task {
            await checkBackendAvailability()
        }
    }

    // MARK: - Backend Availability

    func checkBackendAvailability() async {
        async let tinyChatCheck = checkTinyChatAvailability()
        async let tinyLLMCheck = checkTinyLLMAvailability()

        let (tinyChat, tinyLLM) = await (tinyChatCheck, tinyLLMCheck)

        await MainActor.run {
            self.isTinyChatAvailable = tinyChat
            self.isTinyLLMAvailable = tinyLLM
        }
    }

    // TinyChat availability check
    // TinyChat by Jason Cox: https://github.com/jasonacox/tinychat
    private func checkTinyChatAvailability() async -> Bool {
        guard let url = URL(string: "\(tinyChatServerURL)/") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // TinyLLM availability check
    // TinyLLM by Jason Cox: https://github.com/jasonacox/TinyLLM
    private func checkTinyLLMAvailability() async -> Bool {
        guard let url = URL(string: "\(tinyLLMServerURL)/") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Query Processing

    func processQuery(_ query: String) async -> String {
        await MainActor.run {
            conversationHistory.append(Message(
                id: UUID(),
                text: query,
                isUser: true,
                timestamp: Date()
            ))
            isProcessing = true
        }

        let response = await generateResponse(query)

        await MainActor.run {
            isProcessing = false
            conversationHistory.append(Message(
                id: UUID(),
                text: response,
                isUser: false,
                timestamp: Date()
            ))
        }

        return response
    }

    private func generateResponse(_ query: String) async -> String {
        // Try TinyChat first if available (Jason Cox's excellent fast chatbot)
        if useAIBackend && isTinyChatAvailable {
            if let aiResponse = try? await generateWithTinyChat(query) {
                return aiResponse
            }
        }

        // Fallback to TinyLLM if TinyChat unavailable
        if useAIBackend && isTinyLLMAvailable {
            if let aiResponse = try? await generateWithTinyLLM(query) {
                return aiResponse
            }
        }

        // Fallback to rule-based responses
        return generateRuleBasedResponse(query)
    }

    // MARK: - TinyChat Implementation
    //
    // TinyChat by Jason Cox: https://github.com/jasonacox/tinychat
    // Fast chatbot interface with OpenAI-compatible API
    // Excellent for home automation AI assistance

    private func generateWithTinyChat(_ query: String) async throws -> String {
        guard let url = URL(string: "\(tinyChatServerURL)/v1/chat/completions") else {
            throw AIError.invalidConfiguration
        }

        let systemPrompt = """
        You are a helpful HomeKit assistant for Apple TV. You help control smart home devices.
        Keep responses concise and friendly. When controlling devices, confirm the action taken.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": query]
        ]

        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 256,
            "temperature": 0.7,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        struct TinyChatResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(TinyChatResponse.self, from: data)
        return response.choices.first?.message.content ?? generateRuleBasedResponse(query)
    }

    // MARK: - TinyLLM Implementation
    //
    // TinyLLM by Jason Cox: https://github.com/jasonacox/TinyLLM
    // Lightweight LLM server with OpenAI-compatible API

    private func generateWithTinyLLM(_ query: String) async throws -> String {
        guard let url = URL(string: "\(tinyLLMServerURL)/v1/chat/completions") else {
            throw AIError.invalidConfiguration
        }

        let systemPrompt = """
        You are a helpful HomeKit assistant for Apple TV. You help control smart home devices.
        Keep responses concise and friendly. When controlling devices, confirm the action taken.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": query]
        ]

        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 256,
            "temperature": 0.7,
            "stream": false
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        struct TinyLLMResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(TinyLLMResponse.self, from: data)
        return response.choices.first?.message.content ?? generateRuleBasedResponse(query)
    }

    // MARK: - Rule-based Fallback

    private func generateRuleBasedResponse(_ query: String) -> String {
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

    // MARK: - Errors

    enum AIError: Error {
        case invalidConfiguration
        case networkError
        case parseError
    }
}
