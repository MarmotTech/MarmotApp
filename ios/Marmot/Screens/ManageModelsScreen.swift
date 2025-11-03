import SwiftUI

struct ManageModelsScreen: View {
    @EnvironmentObject private var modelManager: ModelManager
    @EnvironmentObject private var router: Router
    
    @State private var installedModels: [ModelInfo] = []
    @State private var missingModels: [ModelInfo] = []
    
    @State private var showHuggingFaceSheet: Bool = false

    var body: some View {
        ZStack {
            // Modern background
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
                // Modern header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button(action: {
                            router.pop()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.text)
                        }
                        
                        Spacer()
                        
                        Text("Manage Models")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.text)
                        
                        Spacer()
                        
                        // Placeholder for alignment
                        Color.clear
                            .frame(width: 30, height: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    if modelManager.isDownloading {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Downloading...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.text)
                                
                                Spacer()
                                
                                Text("\(Int(modelManager.downloadProgress * 100))%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            ProgressView(value: modelManager.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .main))
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.gray.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
                )
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Installed Models Section
                        if !installedModels.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Installed Models")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.text)
                                
                                VStack(spacing: 12) {
                                    ForEach(installedModels) { model in
                                        ModelManagementCard(
                                            model: model,
                                            isInstalled: true,
                                            onAction: {
                                                Task {
                                                    try? await modelManager.removeModels(models: [model])
                                                    updateModels()
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Available Models Section
                        if !missingModels.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Models")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.text)
                                
                                VStack(spacing: 12) {
                                    ForEach(missingModels) { model in
                                        if let downloadInfo = modelManager.downloadInfo[model.modelName] {
                                            // Show download progress card
                                            ModelDownloadCard(
                                                model: model,
                                                downloadInfo: downloadInfo,
                                                isPaused: modelManager.isPaused[model.modelName] ?? false,
                                                onPause: {
                                                    modelManager.pauseDownload(modelName: model.modelName)
                                                },
                                                onResume: {
                                                    Task {
                                                        await modelManager.resumeDownload(model: model)
                                                    }
                                                },
                                                onCancel: {
                                                    modelManager.cancelDownload(modelName: model.modelName)
                                                    updateModels()
                                                }
                                            )
                                        } else {
                                            ModelManagementCard(
                                                model: model,
                                                isInstalled: false,
                                                isDownloading: false,
                                                onAction: {
                                                    Task {
                                                        await modelManager.downloadModels(models: [model])
                                                        updateModels()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        // hide hugging face ...
                        // Import from Hugging Face
//                        VStack(spacing: 16) {
//                            Image(systemName: "square.and.arrow.down")
//                                .font(.system(size: 32))
//                                .foregroundColor(.gray.opacity(0.5))
//                            
//                            Text("Want more models?")
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(.text)
//                            
//                            Text("Import custom models from Hugging Face")
//                                .font(.system(size: 14))
//                                .foregroundColor(.gray)
//                                .multilineTextAlignment(.center)
//                            
//                            Button(action: {
//                                showHuggingFaceSheet.toggle()
//                            }) {
//                                HStack {
//                                    Image("HuggingFaceLogo")
//                                        .resizable()
//                                        .frame(width: 20, height: 20)
//                                    Text("Import from Hugging Face")
//                                }
//                                .font(.system(size: 16, weight: .semibold))
//                                .foregroundColor(.white)
//                                .padding(.horizontal, 24)
//                                .padding(.vertical, 12)
//                                .background(
//                                    LinearGradient(
//                                        colors: [.orange, .orange.opacity(0.8)],
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                                .cornerRadius(25)
//                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 30)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color.gray.opacity(0.05))
//                        )
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showHuggingFaceSheet) {
            HuggingFaceSheet()
        }
        .onAppear {
            updateModels()
        }
        .task {
            await modelManager.fetchModels()
            updateModels()
        }
    }
    
    private func updateModels() {
        DispatchQueue.main.async {
            installedModels = modelManager.installedModels()
            missingModels = modelManager.missingModels()
        }
    }
}

struct ModelManagementCard: View {
    let model: ModelInfo
    let isInstalled: Bool
    var isDownloading: Bool = false
    let onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Model icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isInstalled ? [.green, .green.opacity(0.8)] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: isInstalled ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.text)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                    Text(model.formattedSize)
                        .font(.system(size: 12))
                    
                    if isInstalled {
                        Text("•")
                            .foregroundColor(.gray)
                        Text("Installed")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onAction) {
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isInstalled ? "trash" : "arrow.down.to.line")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isInstalled ? .red : .main)
                }
            }
            .disabled(isDownloading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ModelDownloadCard: View {
    let model: ModelInfo
    let downloadInfo: DownloadInfo
    let isPaused: Bool
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Model icon with progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: downloadInfo.progress)
                        .stroke(
                            LinearGradient(
                                colors: isPaused ? [.orange, .orange.opacity(0.8)] : [.main, .main.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(downloadInfo.progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isPaused ? .orange : .main)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.text)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(downloadInfo.formattedDownloaded) / \(downloadInfo.formattedSize)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        if !isPaused && downloadInfo.downloadSpeed > 0 {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(downloadInfo.formattedSpeed)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        } else if isPaused {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Paused")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: isPaused ? onResume : onPause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isPaused ? .main : .orange)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isPaused ? [.orange.opacity(0.6), .orange] : [.main.opacity(0.6), .main],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * downloadInfo.progress, height: 8)
                }
            }
            .frame(height: 8)
            
            if !isPaused && downloadInfo.estimatedTimeRemaining > 0 && !downloadInfo.estimatedTimeRemaining.isInfinite {
                HStack {
                    Spacer()
                    Text("Remaining: \(downloadInfo.formattedTimeRemaining)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
