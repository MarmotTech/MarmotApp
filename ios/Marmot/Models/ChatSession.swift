import Foundation
import SwiftData

@Model
class ChatSession: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var modelName: String
    var modelInfo: ModelInfo?
    
    @Relationship(deleteRule: .cascade, inverse: \ChatItem.session)
    var messages: [ChatItem] = []
    
    init(title: String, modelName: String, modelInfo: ModelInfo? = nil, createdAt: Date = Date()) {
        self.title = title
        self.modelName = modelName
        self.modelInfo = modelInfo
        self.createdAt = createdAt
        self.lastMessageAt = createdAt
    }
    
    func addMessage(_ message: ChatItem) {
        messages.append(message)
        message.session = self
        lastMessageAt = Date()
        
        // Auto-generate title from first user message if still default
        if title.hasPrefix("New Chat") && message.type == .userMessage && !message.text.isEmpty {
            title = String(message.text.prefix(30)) + (message.text.count > 30 ? "..." : "")
        }
    }
    
    var sortedMessages: [ChatItem] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
}