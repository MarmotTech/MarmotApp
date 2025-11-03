import SwiftUI
import SwiftData

struct BenchmarkScreen: View {
    @State private var showCreateSheet = false
    @Environment(\.modelContext) private var modelContext
    @Query private var benchmarkResults: [BenchmarkResult]
    @EnvironmentObject private var modelManager: ModelManager
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            // Modern gradient background (matching ModelsScreen)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header with modern styling
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Benchmarks")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.text, .text.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("\(benchmarkResults.count) results")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            router.pop()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.98, green: 0.98, blue: 1.0),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
                )

                if benchmarkResults.isEmpty {
                    // Empty state
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("No benchmark results yet")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)

                        Text("Create a benchmark to compare model performance")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                } else {
                    // Benchmark results list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(benchmarkResults, id: \.id) { result in
                                BenchmarkResultCard(result: result, modelManager: modelManager)
                            }
                            Spacer().frame(height: 120)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }

            // Floating action buttons
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    if !benchmarkResults.isEmpty {
                        Button(action: exportResults) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.text)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                        }
                    }

                    Button(action: {
                        showCreateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("New Benchmark")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.main, .main.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .main.opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showCreateSheet) {
            BenchmarkSheet {
                showCreateSheet = false
                guard let results = $0 else {
                    return
                }

                for result in results {
                    modelContext.insert(result)
                }
                try? modelContext.save()
            }
        }
    }

    private func exportResults() {
        // TODO: Implement export functionality
        print("Export benchmark results")
    }
}

// Modern benchmark result card
struct BenchmarkResultCard: View {
    let result: BenchmarkResult
    let modelManager: ModelManager
    @State private var isExpanded = false

    private var modelName: String {
        modelManager.models.first {
            $0.modelLocalPath == (result.modelName as NSString).lastPathComponent
        }?.displayName ?? (result.modelName as NSString).lastPathComponent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.text)

                        HStack(spacing: 16) {
                            // Key metrics preview
                            Label("\(String(format: "%.1f", result.decodeThroughput)) t/s", systemImage: "speedometer")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)

                            if let firstTask = result.taskResults.sorted(by: { $0.key < $1.key }).first {
                                Label("\(firstTask.key): \(String(format: "%.3f", firstTask.value))", systemImage: "checkmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.main.opacity(0.8))
                }
                .padding(16)
            }

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                // Detailed metrics
                VStack(alignment: .leading, spacing: 16) {
                    // Task results
                    if !result.taskResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Results")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondaryText)

                            ForEach(result.taskResults.sorted(by: { $0.key < $1.key }), id: \.key) { taskName, taskValue in
                                HStack {
                                    Text(taskName)
                                        .font(.system(size: 14))
                                        .foregroundColor(.text)
                                    Spacer()
                                    Text(String(format: "%.3f", taskValue))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.main)
                                }
                            }
                        }
                    }

                    // Performance metrics
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondaryText)

                        HStack(spacing: 20) {
                            MetricPill(
                                icon: "arrow.down.circle",
                                label: "Decode",
                                value: String(format: "%.1f t/s", result.decodeThroughput),
                                color: .main
                            )

                            MetricPill(
                                icon: "arrow.up.circle",
                                label: "TTFT",
                                value: String(format: "%.1f s", result.timeToFirstToken),
                                color: .main
                            )
                        }
                    }

                    // Model info
                    HStack(spacing: 20) {
                        MetricPill(
                            icon: "cpu",
                            label: "Params",
                            value: result.modelParams >= 1_000_000_000
                                ? String(format: "%.1fB", Float(result.modelParams) / 1_000_000_000)
                                : String(format: "%.0fM", Float(result.modelParams) / 1_000_000),
                            color: .gray
                        )

                        MetricPill(
                            icon: "internaldrive",
                            label: "Size",
                            value: result.modelSize >= 1_073_741_824
                                ? String(format: "%.1f GB", Float(result.modelSize) / (1024 * 1024 * 1024))
                                : String(format: "%.0f MB", Float(result.modelSize) / (1024 * 1024)),
                            color: .gray
                        )
                    }

                    // Thread count info
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(result.numThreads) threads")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer().frame(width: 20)
                        
                        Image(systemName: "internaldrive")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(String(format: "%.1fGB", result.memorySize))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .padding(.top, -8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// Reusable metric pill component
struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.text)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct BenchmarkScreen_Previews: PreviewProvider {
    static var previews: some View {
        BenchmarkScreen()
    }
}
