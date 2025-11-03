class Config {
    let threadNum: Int32 = 32
    let contextSize: Int32 = 512
    let benchmarkPromptLength: Int32 = 16
    let benchmarkGenerationSize: Int32 = 16
    
    static let `default` = Config()
}
