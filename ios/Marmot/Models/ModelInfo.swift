import Foundation

struct ModelInfo: Codable, Hashable, Identifiable {
    var id: String {
        modelName
    }
    
    var modelName: String
    var modelUrl: URL
    var modelLocalPath: String
    var modelSize: Int
    var prefetchThread: Int
    var systemPrompt: String
    var tasks: [String]?
}

extension ModelInfo {
    static var mock: ModelInfo {
        ModelInfo(
            modelName: "tinyllama-1.1b-chat-v1.0",
            modelUrl: URL(
                string: "https://conference.cs.cityu.edu.hk/saccps/app/models/ggml-model-tinyllama-1.1b-chat-v1.0-q4_0.gguf"
            )!,
            modelLocalPath: "ggml-model-tinyllama-1.1b-chat-v1.0-q4_0.gguf",
            modelSize: 636726304,
            prefetchThread: 0,
            systemPrompt: "You are a friendly chatbot who always responds in the style of a pirate",
            tasks: ["perplexity"]
        )
    }
}
