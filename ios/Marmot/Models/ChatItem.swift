import Foundation
import SwiftData

@Model
class ChatItem: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var text: String
    var type: ChatItemType
    var timestamp: Date
    var session: ChatSession?

    init(type: ChatItemType, text: String, timestamp: Date = Date()) {
        self.type = type
        self.text = text
        self.timestamp = timestamp
    }


    func appendText(_ newText: String) {
        self.text += newText
    }
}

enum ChatItemType: String, Codable, CaseIterable {
    case userMessage = "user"
    case botMessage = "bot"
}
