import Foundation

enum ModelManagerError: LocalizedError {
    case networkError(String)
    case downloadError(String)
    case fileSystemError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .downloadError(let message):
            return "Download Error: \(message)"
        case .fileSystemError(let message):
            return "File System Error: \(message)"
        case .decodingError(let message):
            return "Data Error: \(message)"
        }
    }
}

struct DownloadInfo {
    let modelName: String
    let totalBytes: Int64
    let downloadedBytes: Int64
    let progress: Double
    let downloadSpeed: Double // bytes per second
    let estimatedTimeRemaining: TimeInterval
    
    var formattedSize: String {
        let gigabytes = Double(totalBytes) / (1024 * 1024 * 1024)
        if gigabytes >= 1.0 {
            return String(format: "%.1f GB", gigabytes)
        } else {
            let megabytes = Double(totalBytes) / (1024 * 1024)
            return String(format: "%.0f MB", megabytes)
        }
    }
    
    var formattedDownloaded: String {
        let gigabytes = Double(downloadedBytes) / (1024 * 1024 * 1024)
        if gigabytes >= 1.0 {
            return String(format: "%.1f GB", gigabytes)
        } else {
            let megabytes = Double(downloadedBytes) / (1024 * 1024)
            return String(format: "%.0f MB", megabytes)
        }
    }
    
    var formattedSpeed: String {
        let megabytesPerSec = downloadSpeed / (1024 * 1024)
        if megabytesPerSec >= 1.0 {
            return String(format: "%.1f MB/s", megabytesPerSec)
        } else {
            let kilobytesPerSec = downloadSpeed / 1024
            return String(format: "%.0f KB/s", kilobytesPerSec)
        }
    }
    
    var formattedTimeRemaining: String {
        if estimatedTimeRemaining.isInfinite || estimatedTimeRemaining.isNaN {
            return "Calculating..."
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: estimatedTimeRemaining) ?? "Unknown"
    }
}

@MainActor
class ModelManager: ObservableObject {
    @Published var models: [ModelInfo] = []
    @Published var downloadProgress: Double = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var downloadInfo: [String: DownloadInfo] = [:]
    @Published var isPaused: [String: Bool] = [:]
    
    @Published private var progressObservers: [String:NSKeyValueObservation] = [:]
    @Published private var downloadTasks: [String:URLSessionDownloadTask] = [:]
    private var downloadStartTimes: [String: Date] = [:]
    private var lastProgressUpdate: [String: (Date, Int64)] = [:]
    private var resumeData: [String: Data] = [:]
    private var speedSamples: [String: [Double]] = [:] // Keep last few speed samples for smoothing
    
    var isDownloading: Bool {
        !downloadTasks.isEmpty
    }
    
    func fetchModels() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            guard let url = URL(string: "https://conference.cs.cityu.edu.hk/saccps/app/models/models.json") else {
                throw ModelManagerError.networkError("Invalid URL")
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ModelManagerError.networkError("Server returned error status")
            }
            
            let decodedModels = try JSONDecoder().decode([ModelInfo].self, from: data)
            print("✅ fetch models.json suc,datas count:\(decodedModels.count)")
            for model in decodedModels {
                print(model)
            }
            self.models = decodedModels
            self.isLoading = false
            
        } catch _ as DecodingError {
            DispatchQueue.main.async {
                self.errorMessage = ModelManagerError.decodingError("Failed to parse model data").localizedDescription
                self.isLoading = false
            }
        } catch let error as ModelManagerError {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = ModelManagerError.networkError("Failed to fetch models. Please check your internet connection.").localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func modelDownloading(model: ModelInfo) -> Bool {
        return downloadTasks[model.modelName] != nil
    }
    
    func installedModels() -> [ModelInfo] {
        return models.filter {
            let modelPath = URL.documentsDirectory.appending(path: $0.modelLocalPath).path()
            
            return FileManager.default.fileExists(atPath: modelPath)
        }
    }
    
    func missingModels() -> [ModelInfo] {
        return models.filter {
            let modelPath = URL.documentsDirectory.appending(path: $0.modelLocalPath).path()
            
            return !FileManager.default.fileExists(atPath: modelPath)
        }
    }
    
    func removeModels(models: [ModelInfo]) async throws {
        for model in models {
            let modelPath = URL.documentsDirectory.appending(path: model.modelLocalPath).path()
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.global(qos: .utility).async {
                    do {
                        try FileManager.default.removeItem(atPath: modelPath)
                        sync()
                    } catch {
                        print(error)
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    func downloadModels(models: [ModelInfo]) async {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
        
        do {
            try await withThrowingTaskGroup(of: ModelInfo.self) { group in
                for model in models {
                    group.addTask {
                        let modelPath = URL.documentsDirectory.appending(path: model.modelLocalPath)
                        
                        try await self.downloadModelToFile(model, destination: modelPath)
                        return model
                    }
                }
                
                while let completedModel = try await group.next() {
                    print("Downloaded model: \(completedModel.modelLocalPath)")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = ModelManagerError.downloadError("Failed to download model: \(error.localizedDescription)").localizedDescription
            }
        }
    }
    
    func pauseDownload(modelName: String) {
        guard let task = downloadTasks[modelName] else { return }
        
        task.cancel { resumeDataOrNil in
            if let resumeData = resumeDataOrNil {
                DispatchQueue.main.async {
                    self.resumeData[modelName] = resumeData
                    self.isPaused[modelName] = true
                }
            }
        }
    }
    
    func resumeDownload(model: ModelInfo) async {
        let modelPath = URL.documentsDirectory.appending(path: model.modelLocalPath)
        if let resumeData = resumeData[model.modelName] {
            self.resumeData.removeValue(forKey: model.modelName)
            self.isPaused[model.modelName] = false
            // Reset speed tracking when resuming
            self.lastProgressUpdate.removeValue(forKey: model.modelName)
            self.speedSamples.removeValue(forKey: model.modelName)
            try? await downloadModelToFile(model, destination: modelPath, resumeData: resumeData)
        } else {
            try? await downloadModelToFile(model, destination: modelPath)
        }
    }
    
    func cancelDownload(modelName: String) {
        if let task = downloadTasks[modelName] {
            task.cancel()
            cleanupDownloadTask(modelName)
            resumeData.removeValue(forKey: modelName)
            isPaused.removeValue(forKey: modelName)
        }
    }
    
    private func downloadModelToFile(_ model: ModelInfo, destination: URL, resumeData: Data? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let taskID = model.modelName
            
            let task: URLSessionDownloadTask
            if let resumeData = resumeData {
                task = URLSession.shared.downloadTask(withResumeData: resumeData) { tempURL, response, error in
                    Task { @MainActor in
                        self.handleDownloadCompletion(tempURL: tempURL, response: response, error: error, destination: destination, taskID: taskID, continuation: continuation)
                    }
                }
            } else {
                task = URLSession.shared.downloadTask(with: model.modelUrl) { tempURL, response, error in
                    Task { @MainActor in
                        self.handleDownloadCompletion(tempURL: tempURL, response: response, error: error, destination: destination, taskID: taskID, continuation: continuation)
                    }
                }
            }
            
            self.setupDownloadTask(task: task, taskID: taskID)
            task.resume()
        }
    }
    
    private func handleDownloadCompletion(tempURL: URL?, response: URLResponse?, error: Error?, destination: URL, taskID: String, continuation: CheckedContinuation<Void, Error>) {
        if let error = error as NSError? {
            if error.code == NSURLErrorCancelled {
                if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self.resumeData[taskID] = resumeData
                    self.isPaused[taskID] = true
                }
            }
            self.cleanupDownloadTask(taskID)
            continuation.resume(throwing: error)
            return
        }
        
        guard let tempURL = tempURL else {
            self.cleanupDownloadTask(taskID)
            continuation.resume(
                throwing: NSError(domain: "DownloadError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No file downloaded"])
            )
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            
            try FileManager.default.moveItem(at: tempURL, to: destination)
            self.cleanupDownloadTask(taskID)
            continuation.resume()
        } catch {
            self.cleanupDownloadTask(taskID)
            continuation.resume(throwing: error)
        }
    }
    
    private func setupDownloadTask(task: URLSessionDownloadTask, taskID: String) {
        let observer = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.updateDownloadProgress(taskID: taskID, progress: progress)
            }
        }
        
        let totalBytesObserver = task.progress.observe(\.totalUnitCount) { progress, _ in
            DispatchQueue.main.async {
                self.updateDownloadProgress(taskID: taskID, progress: progress)
            }
        }
        
        DispatchQueue.main.async {
            self.progressObservers[taskID] = observer
            self.progressObservers["\(taskID)_total"] = totalBytesObserver
            self.downloadTasks[taskID] = task
            self.downloadStartTimes[taskID] = Date()
            self.isPaused[taskID] = false
        }
    }
    
    private func updateDownloadProgress(taskID: String, progress: Progress) {
        let currentTime = Date()
        let totalBytes = progress.totalUnitCount
        let downloadedBytes = progress.completedUnitCount
        let progressValue = progress.fractionCompleted
        
        // Calculate instantaneous download speed
        var downloadSpeed: Double = 0
        var estimatedTimeRemaining: TimeInterval = .infinity
        
        // Use instantaneous speed calculation
        if let lastUpdate = lastProgressUpdate[taskID] {
            let timeDelta = currentTime.timeIntervalSince(lastUpdate.0)
            let bytesDelta = downloadedBytes - lastUpdate.1
            
            if timeDelta > 0.1 && bytesDelta > 0 { // Update at least every 0.1 seconds
                let instantSpeed = Double(bytesDelta) / timeDelta
                
                // Keep a sliding window of speed samples for smoothing
                if speedSamples[taskID] == nil {
                    speedSamples[taskID] = []
                }
                speedSamples[taskID]?.append(instantSpeed)
                
                // Keep only last 5 samples
                if speedSamples[taskID]!.count > 5 {
                    speedSamples[taskID]?.removeFirst()
                }
                
                // Calculate average speed from samples
                if let samples = speedSamples[taskID], !samples.isEmpty {
                    downloadSpeed = samples.reduce(0, +) / Double(samples.count)
                }
                
                // Update last progress for next calculation
                lastProgressUpdate[taskID] = (currentTime, downloadedBytes)
            } else if timeDelta <= 0.1 {
                // Use previous speed if update is too frequent
                if let info = downloadInfo[taskID] {
                    downloadSpeed = info.downloadSpeed
                }
            }
        } else {
            // First update - initialize
            lastProgressUpdate[taskID] = (currentTime, downloadedBytes)
            speedSamples[taskID] = []
        }
        
        // Calculate estimated time remaining based on current speed
        if downloadSpeed > 0 {
            let remainingBytes = totalBytes - downloadedBytes
            estimatedTimeRemaining = Double(remainingBytes) / downloadSpeed
        }
        
        // Create download info
        let info = DownloadInfo(
            modelName: taskID,
            totalBytes: totalBytes,
            downloadedBytes: downloadedBytes,
            progress: progressValue,
            downloadSpeed: downloadSpeed,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        
        downloadInfo[taskID] = info
        
        // Update overall progress
        downloadProgress = downloadTasks.reduce(0) {
            $0 + $1.value.progress.fractionCompleted
        } / Double(downloadTasks.count)
    }
    
    private func cleanupDownloadTask(_ taskID: String) {
        DispatchQueue.main.async {
            if let observer = self.progressObservers.removeValue(forKey: taskID) {
                observer.invalidate()
            }
            if let totalObserver = self.progressObservers.removeValue(forKey: "\(taskID)_total") {
                totalObserver.invalidate()
            }
            self.downloadTasks.removeValue(forKey: taskID)
            self.downloadStartTimes.removeValue(forKey: taskID)
            self.lastProgressUpdate.removeValue(forKey: taskID)
            self.speedSamples.removeValue(forKey: taskID)
            self.downloadInfo.removeValue(forKey: taskID)
            self.isPaused.removeValue(forKey: taskID)
        }
    }
}
