import SwiftUI
import AVKit

struct BenchmarkSheet: View {
    @EnvironmentObject private var modelManager: ModelManager
    @StateObject private var llama = Llama()

    @State private var isRunning = false
    @State private var selectedModels: [ModelInfo] = []
    @State private var selectedTasks: [String] = []
    @State private var threadCount = 2//default is 2 C
    @State private var memorySize : Float = 2.0 //default is 2 GB
    private let maxMemory : Float = 99
    private let maxThread = 99
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    var onComplete: (([BenchmarkResult]?) -> Void)

    var body: some View {
        VStack(spacing: 0) {
            if isRunning {
                // Running state with modern design
                VStack(spacing: 24) {
                    // Progress header
                    VStack(spacing: 12) {
                        LoopingVideoPlayer(videoURL: Bundle.main.url(forResource: "Loader", withExtension: "mp4")!)
                            .disabled(true)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)

                        Text("Running Benchmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.text, .text.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Please wait while we test your models")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    // Status information
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .font(.system(size: 14))
                                .foregroundColor(.main)
                            Text("\(selectedModels.count) model\(selectedModels.count == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundColor(.text)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.main)
                            Text("\(selectedTasks.count) task\(selectedTasks.count == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundColor(.text)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.tertiary.opacity(0.5))
                    )
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Setup state with modern design
                VStack(spacing: 0) {
                    // Sheet handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("New Benchmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.text, .text.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }

                        Text("Compare model performance across tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Model selection section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Select Models", systemImage: "cpu")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.text)

                                VStack(spacing: 8) {
                                    ForEach(modelManager.installedModels(), id: \.modelName) { model in
                                        ModernSelectableRow(
                                            text: model.displayName,
                                            subtitle: model.formattedSize,
                                            selected: selectedModels.contains(model)
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if selectedModels.contains(model) {
                                                    selectedModels.removeAll { $0 == model }
                                                    selectedTasks.removeAll()
                                                } else {
                                                    selectedModels.removeAll()
                                                    selectedTasks.removeAll()
                                                    memorySize = 2
                                                    threadCount = 2
                                                    selectedModels.append(model)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Task selection section
                            if !selectedModels.isEmpty {
                                
                                
                                // Thread and Memory Configuration
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Configuration")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.text)
                                        
                                        Spacer()
                                        
                                        Text(selectedModels.first?.modelName ?? "")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.top, 20)
                                    
                                    VStack(spacing: 12) {
                                        // Thread configuration
                                        HStack {
                                            Label("Threads", systemImage: "cpu")
                                                .font(.system(size: 15))
                                                .foregroundColor(.text)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                Button(action: {
                                                    if threadCount > 1 {
                                                        threadCount -= 1
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(threadCount > 1 ? .main : .gray.opacity(0.3))
                                                }
                                                .disabled(threadCount <= 1)
                                                
                                                Text("\(threadCount)")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.text)
                                                    .frame(minWidth: 30)
                                                
                                                Button(action: {
                                                    if threadCount < maxThread {
                                                        threadCount += 1
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(threadCount < maxThread ? .main : .gray.opacity(0.3))
                                                }
                                                .disabled(threadCount >= maxThread)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                        
                                        // Memory configuration
                                        HStack {
                                            Label("Memory", systemImage: "memorychip")
                                                .font(.system(size: 15))
                                                .foregroundColor(.text)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                Button(action: {
                                                    if memorySize > 1 {
                                                        memorySize -= 0.2
                                                    }
                                                }) {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(memorySize > 1 ? .main : .gray.opacity(0.3))
                                                }
                                                .disabled(memorySize <= 1)
                                                
                                                Text(String(format: "%.1fGB", memorySize))
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.text)
                                                    .frame(minWidth: 45)
                                                
                                                Button(action: {
                                                    if memorySize < maxMemory {
                                                        memorySize += 0.2
                                                    }
                                                }) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(memorySize < maxMemory ? .main : .gray.opacity(0.3))
                                                }
                                                .disabled(memorySize >= maxMemory)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    }
                                }
                                
                                
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Select Tasks", systemImage: "checkmark.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.text)

                                    VStack(spacing: 8) {
//                                        ForEach(selectedModels.flatMap { $0.tasks ?? [] }.unique(), id: \.self) { task in
                                        ForEach(selectedModels.first?.tasks?.unique().sorted(by: <) ?? [], id: \.self) { task in
                                            ModernSelectableRow(
                                                text: task,
                                                subtitle: nil,
                                                selected: selectedTasks.contains(task)
                                            ) {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    if selectedTasks.contains(task) {
                                                        selectedTasks.removeAll { $0 == task }
                                                    } else {
                                                        selectedTasks.append(task)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    }

                    // Bottom action area
                    VStack(spacing: 16) {
                        if !selectedModels.isEmpty && !selectedTasks.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.main)
                                Text("This will run \(selectedModels.count * selectedTasks.count) benchmark\(selectedModels.count * selectedTasks.count == 1 ? "" : "s")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.main.opacity(0.1))
                            )
                        }

                        Button(action: startBenchmark) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start Benchmark")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: selectedTasks.isEmpty ? [Color.gray, Color.gray] : [.main, .main.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(
                                        color: selectedTasks.isEmpty ? .clear : .main.opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                        }
                        .disabled(selectedTasks.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .padding(.top, 16)
                }
            }
        }
        .presentationBackground(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white,
                    Color(red: 0.98, green: 0.98, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .interactiveDismissDisabled(isRunning)
        .presentationDetents(isRunning ? [.height(400)] : [])
    }

    private func startBenchmark() {
        withAnimation {
            isRunning = true
        }
        var model : String? = nil
        if let selectedLocalPath = selectedModels.first?.modelLocalPath {
            model = URL.documentsDirectory.appending(path: selectedLocalPath).path()
        }
        llama.runBenchmark(model: model,
                           threadNum: self.threadCount,
                           memorySize: self.memorySize,
                           tasks: selectedTasks) { results in
            onComplete(results)
        }
    }
}

// Modern selectable row with improved design
struct ModernSelectableRow: View {
    let text: String
    let subtitle: String?
    let selected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selected ? .main : .gray.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: selected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.system(size: 15, weight: selected ? .medium : .regular))
                        .foregroundColor(.text)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.main)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, subtitle != nil ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.main.opacity(0.08) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected ? Color.main.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: selected ? .main.opacity(0.1) : .black.opacity(0.02), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        Array(Set(self))
    }
}
