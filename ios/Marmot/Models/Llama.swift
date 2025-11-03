import Foundation
import SwiftData

extension Notification.Name {
    static let llamaOutputReceived = Notification.Name("llamaOutputReceived")
    static let llamaProgressUpdated = Notification.Name("llamaProgressUpdated")
    static let llamaBenchmarkFinished = Notification.Name("llamaBenchmarkFinished")
}

class Llama: ObservableObject {
    @Published var chatStarted: Bool = false
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var messages: [ChatItem] = []
    @Published var currentSession: ChatSession?
    @Published var errorMessage: String?
    
    private var observers: [NSObjectProtocol] = []
    private var modelContext: ModelContext?
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    func stopChatSf() {
        DispatchQueue.global(qos: .default).async {
            print("✅ ios call stopChat")
            stopChat()
        }
    }
    func start(modelInfo: ModelInfo, modelContext: ModelContext, existingSession: ChatSession? = nil, threadNum: Int = 2, memorySize: Float = 2) {
        self.modelContext = modelContext
        isLoading = true
        errorMessage = nil
        
        // Check if model file exists
        let localModelPath = URL.documentsDirectory.appending(path: modelInfo.modelLocalPath).path()
        guard FileManager.default.fileExists(atPath: localModelPath) else {
            errorMessage = "Model file not found. Please download the model first."
            isLoading = false
            return
        }
        
        // Create or load session
        if let session = existingSession {
            currentSession = session
            messages = session.sortedMessages
        } else {
            let newSession = ChatSession(
                title: "New Chat with \(modelInfo.modelName)",
                modelName: modelInfo.modelName,
                modelInfo: modelInfo
            )
            modelContext.insert(newSession)
            currentSession = newSession
            messages = []
        }
        
        let observer = NotificationCenter.default.addObserver(
            forName: .llamaOutputReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let response = notification.object as? String {
                self.objectWillChange.send()
                if self.messages.count > 0 {
                    let lastMessage = self.messages[self.messages.count - 1]
                    lastMessage.appendText(response)
                    
                    if let session = self.currentSession,
                       let persistentMessage = session.messages.last(where: { $0.id == lastMessage.id }) {
                        persistentMessage.text = lastMessage.text
                        try? self.modelContext?.save()
                    }

                    if response.contains("\n\n") || response.isEmpty {
                        self.isGenerating = false
                    }
                }
            }
        }
        self.observers.append(observer)
        
        DispatchQueue.global(qos: .default).async {
            print("✅ ios call startChatWPrefetch")
            startChatWPrefetch(
                localModelPath,
                modelInfo.systemPrompt,
                Int32(threadNum),
                1,
                Float(memorySize),
                256,
                { (str: UnsafePointer<CChar>?) in
                    if let str, let string = String(cString: str, encoding: .utf8) {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .llamaOutputReceived, object: string)
                        }
                    }
                },
                { (_, _) in }
            )
            
            DispatchQueue.main.async {
                self.chatStarted = true
                self.isLoading = false
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard let session = currentSession else { return }
        
        isGenerating = true
        
        // Create and add user message
        let userMessage = ChatItem(type: .userMessage, text: message)
        let botMessage = ChatItem(type: .botMessage, text: "")
        
        // Add to local array for UI
        messages.append(userMessage)
        messages.append(botMessage)
        
        // Add to persistent session
        session.addMessage(userMessage)
        session.addMessage(botMessage)
        
        // Save to database
        if let context = modelContext {
            context.insert(userMessage)
            context.insert(botMessage)
            try? context.save()
        }
        print("✅ ios call inputString")
        inputString(message)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func runBenchmark(
        model: String?,
        threadNum:Int,
        memorySize: Float,
        tasks: [String],
        onComplete: @escaping ([BenchmarkResult]?) -> Void
    ) {
        guard let model else { return }
        
        let observer = NotificationCenter.default.addObserver(
            forName: .llamaBenchmarkFinished,
            object: nil,
            queue: .main
        ) { notification in
            if let response = notification.object as? String {
                do {
                    let result = try JSONDecoder().decode(BenchmarkResult.self, from: Data(response.utf8))
                      onComplete([result])  
                } catch {
                    print(error)
                    onComplete(nil)
                    return
                }
            }
        }
        self.observers.append(observer)
        
//        runBenchmarkTestDebug()
//        return
        
        let perplexityFile = Bundle.main.path(forResource: "wikitext-2.test", ofType: "raw")!
        
        DispatchQueue.global(qos: .default).async {
            let cTasks = tasks.toCStringArray()
            let cModel = model.stringToCString()
            print("✅ ios call startBenchmark")
            startBenchmark(
                cModel,
                Int32(threadNum),
                Int32(1),
                Float(memorySize),
                Config.default.contextSize,
                Config.default.benchmarkPromptLength,
                Config.default.benchmarkGenerationSize,
                cTasks,
                Int32(tasks.count),
                perplexityFile,
                { (str: UnsafePointer<CChar>?) in
                    if let str, let string = String(cString: str, encoding: .utf8) {
                        print(string)
                        NotificationCenter.default.post(name: .llamaBenchmarkFinished, object: string)
                    }
                }
            )
            
            freeCStringArray(cTasks, count: tasks.count)
        }
    }
    
    func runBenchmarkTestDebug() {
        DispatchQueue.global(qos: .default).async {
            let result = """
{"model_name":"/var/mobile/Containers/Data/Application/AFD91BE8-53FC-4C20-83F1-18393775FC28/Documents/ggml-model-tinyllama-1.1b-chat-v1.0-q4_0.gguf", "model_size":635990016, "model_n_params":1100048384, "num_threads":2, "memory_size":2.000000, "time_to_first_token":1.861454, "decode_throughput":32.349915}
"""
            print(result)
            NotificationCenter.default.post(name: .llamaBenchmarkFinished, object: result)
        }
    }
}

