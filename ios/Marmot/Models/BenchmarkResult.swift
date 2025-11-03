import Foundation
import SwiftData
/**
 {"model_name":"/var/mobile/Containers/Data/Application/EF7F6C47-055F-42C4-BE33-8893B6FAAA3E/Documents/ggml-model-tinyllama-1.1b-chat-v1.0-q4_0.gguf", "model_size":635990016,
 "model_n_params":1100048384,
 "num_threads":2,
 "time_to_first_token":164.493515,
 "decode_throughput":10.978320}
 */
@Model
class BenchmarkResult: Identifiable, Decodable {
    @Attribute(.unique) var id: UUID = UUID()
    var modelSize: Int
    var modelName: String
    var modelParams: Int
    var numThreads: Int
    var memorySize: Float
    var prefillThroughput: Float
    var decodeThroughput: Float
    var taskResults: [String: Float]
    var timeToFirstToken: Float
    
    enum CodingKeys: String, CodingKey {
        case modelSize = "model_size"
        case modelName = "model_name"
        case modelParams = "model_n_params"
        case numThreads = "num_threads"
        case memorySize = "memory_size"
        case prefillThroughput = "prefill_throughput"
        case decodeThroughput = "decode_throughput"
        case taskResults = "task_results"
        case timeToFirstToken = "time_to_first_token"
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modelSize = try container.decode(Int.self, forKey: .modelSize)
        modelName = try container.decode(String.self, forKey: .modelName)
        modelParams = try container.decode(Int.self, forKey: .modelParams)
        numThreads = try container.decode(Int.self, forKey: .numThreads)
        memorySize = try container.decodeIfPresent(Float.self, forKey: .memorySize) ?? 0
        prefillThroughput = try container.decodeIfPresent(Float.self, forKey: .prefillThroughput) ?? 0
        decodeThroughput = try container.decodeIfPresent(Float.self, forKey: .decodeThroughput) ?? 0
        taskResults = try container.decodeIfPresent([String: Float].self, forKey: .taskResults) ?? [:]
        timeToFirstToken = try container.decodeIfPresent(Float.self, forKey: .timeToFirstToken) ?? 0
    }
    
    init(modelSize: Int, modelName: String, modelParams: Int, numThreads: Int,memorySize: Float, prefillThroughput: Float, decodeThroughput: Float, taskResults: [String: Float], timeToFirstToken: Float) {
        self.modelSize = modelSize
        self.modelName = modelName
        self.modelParams = modelParams
        self.numThreads = numThreads
        self.prefillThroughput = prefillThroughput
        self.decodeThroughput = decodeThroughput
        self.taskResults = taskResults
        self.timeToFirstToken = timeToFirstToken
        self.memorySize = memorySize
    }
}
