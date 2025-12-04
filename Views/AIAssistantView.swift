import SwiftUI

struct AIAssistantView: View {
    @ObservedObject private var aiManager = AIAssistantManager.shared
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                if aiManager.isProcessing {
                    ProgressView()
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
            .background(Color.gray.opacity(0.05))
            
            // Conversation
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(aiManager.conversationHistory) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                            }
                            
                            Text(message.text)
                                .padding(20)
                                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(message.isUser ? .white : .primary)
                                .cornerRadius(15)
                                .frame(maxWidth: 600, alignment: message.isUser ? .trailing : .leading)
                            
                            if !message.isUser {
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
            }
            
            // Input
            HStack(spacing: 20) {
                TextField("Ask me anything about your home...", text: $inputText)
                    .font(.title3)
                    .padding(20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Button(action: {
                    Task {
                        let query = inputText
                        inputText = ""
                        _ = await aiManager.processQuery(query)
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 45))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 30)
            .background(Color.gray.opacity(0.05))
        }
    }
}