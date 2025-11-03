import SwiftUI
import Foundation

struct DownloadSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isDownloading: Bool = false
    @State private var hasStartedDownload: Bool = false
    @EnvironmentObject private var modelManager: ModelManager

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Download Models")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.text)
                    
                    Text("Download AI models to start chatting locally")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondaryText)
                }
                
                Spacer()
                
                if !isDownloading && hasStartedDownload {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
            .padding(.top, 8)

            if isDownloading {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(modelManager.downloadInfo.values), id: \.modelName) { info in
                            DownloadItemView(
                                info: info,
                                isPaused: modelManager.isPaused[info.modelName] ?? false,
                                onPause: {
                                    modelManager.pauseDownload(modelName: info.modelName)
                                },
                                onResume: {
                                    Task {
                                        if let model = modelManager.models.first(where: { $0.modelName == info.modelName }) {
                                            await modelManager.resumeDownload(model: model)
                                        }
                                    }
                                },
                                onCancel: {
                                    modelManager.cancelDownload(modelName: info.modelName)
                                }
                            )
                        }
                        
                        // Overall progress if multiple downloads
                        if modelManager.downloadInfo.count > 1 {
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Overall Progress")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.text)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(modelManager.downloadProgress * 100))%")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondaryText)
                                }
                                
                                ProgressView(value: modelManager.downloadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .main))
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                .frame(maxHeight: 300)
            } else if modelManager.missingModels().isEmpty {
                // All models downloaded
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("All models downloaded!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.text)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .frame(height: 48)
                            .background(Color.main)
                            .cornerRadius(24)
                    }
                }
                .padding()
            } else {
                // Show models to download
                VStack(spacing: 16) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(modelManager.missingModels(), id: \.modelName) { model in
                                HStack {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 16))
                                        .foregroundColor(.main)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.modelName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.text)
                                        
                                        Text(ByteCountFormatter.string(fromByteCount: Int64(model.modelSize), countStyle: .file))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(24)
                        }
                        
                        Button(action: {
                            isDownloading = true
                            hasStartedDownload = true
                            
                            Task {
                                await modelManager.downloadModels(models: modelManager.missingModels())
                                await MainActor.run {
                                    isDownloading = false
                                }
                            }
                        }) {
                            Text("Download All")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.main)
                                .cornerRadius(24)
                        }
                    }
                }
            }

            if !isDownloading {
                Spacer()
            }
        }
        .padding(24)
        .ignoresSafeArea()
        .interactiveDismissDisabled(isDownloading)
        .presentationBackground(Color.white)
    }
}

struct DownloadItemView: View {
    let info: DownloadInfo
    let isPaused: Bool
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(info.modelName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.text)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isPaused {
                        Button(action: onResume) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.main)
                        }
                    } else {
                        Button(action: onPause) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
                
                Text("\(Int(info.progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondaryText)
                    .frame(width: 40, alignment: .trailing)
            }
            
            ProgressView(value: info.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: isPaused ? .gray : .main))
            
            HStack {
                Text("\(info.formattedDownloaded) / \(info.formattedSize)")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                if !isPaused && info.downloadSpeed > 0 {
                    Text("\(info.formattedSpeed) • \(info.formattedTimeRemaining)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                } else if isPaused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(isPaused ? 0.05 : 0.1))
        .cornerRadius(12)
    }
}