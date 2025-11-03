import Foundation

extension ModelInfo {
    /// Returns a formatted display name with parameter count in billions
    var displayName: String {
        // Extract parameter count from model name
        let components = modelName.lowercased().components(separatedBy: "-")
        
        // Look for patterns like "1.1b", "7b", "13b", "70b", "32b"
        for component in components {
            if component.hasSuffix("b") {
                let numberPart = component.dropLast() // Remove "b"
                if let value = Double(numberPart) {
                    // Already in billions format
                    return formatModelNameWithParams(value)
                }
            }
        }
        
        // Check for special cases
        if modelName.contains("tinyllama") && modelName.contains("1.1") {
            return "TinyLlama (1.1B)"
        } else if modelName.contains("llama-2-7b") {
            return "Llama 2 (7B)"
        } else if modelName.contains("llama-2-13b") {
            return "Llama 2 (13B)"
        } else if modelName.contains("llama-2-70b") {
            return "Llama 2 (70B)"
        } else if modelName.contains("qwen2.5-32b") {
            return "Qwen 2.5 (32B)"
        }
        
        // Fallback to original name
        return modelName
    }
    
    /// Returns model size formatted in GB
    var formattedSize: String {
        let gigabytes = Double(modelSize) / (1024 * 1024 * 1024)
        if gigabytes >= 1.0 {
            return String(format: "%.1f GB", gigabytes)
        } else {
            // For sizes less than 1 GB, show in MB
            let megabytes = Double(modelSize) / (1024 * 1024)
            return String(format: "%.0f MB", megabytes)
        }
    }
    
    /// Returns a short version of the model name for compact displays
    var shortDisplayName: String {
        if modelName.contains("tinyllama") {
            return "TinyLlama 1.1B"
        } else if modelName.contains("llama-2-7b") {
            return "Llama 2 7B"
        } else if modelName.contains("llama-2-13b") {
            return "Llama 2 13B"
        } else if modelName.contains("llama-2-70b") {
            return "Llama 2 70B"
        } else if modelName.contains("qwen2.5-32b") {
            return "Qwen 2.5 32B"
        }
        return modelName
    }
    
    private func formatModelNameWithParams(_ billions: Double) -> String {
        // Extract base model name
        var baseName = ""
        if modelName.lowercased().contains("tinyllama") {
            baseName = "TinyLlama"
        } else if modelName.lowercased().contains("llama-2") {
            baseName = "Llama 2"
        } else if modelName.lowercased().contains("qwen") {
            baseName = "Qwen 2.5"
        } else {
            // Try to extract a reasonable base name
            let parts = modelName.components(separatedBy: "-")
            baseName = parts.first?.capitalized ?? modelName
        }
        
        // Format parameter count
        if billions >= 1.0 {
            let formatted = billions.truncatingRemainder(dividingBy: 1) == 0 
                ? String(format: "%.0fB", billions) 
                : String(format: "%.1fB", billions)
            return "\(baseName) (\(formatted))"
        } else {
            let millions = billions * 1000
            return "\(baseName) (\(String(format: "%.0fM", millions)))"
        }
    }
}