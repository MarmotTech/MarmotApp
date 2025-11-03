import SwiftUI
import SwiftData

struct ModelsScreen: View {
    @EnvironmentObject private var modelManager: ModelManager
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var recentSessions: [ChatSession]
    
    @State private var selectedModel: ModelInfo?
    @State private var showNewChatOptions = false
    @State private var threadNum: Int = 2
    @State private var memorySize: Float = 2
    
    let cpuCount: Int = ProcessInfo.processInfo.processorCount
    let maxMemory: Float = 8

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
                // Fixed header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Model")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.text, .text.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("\(modelManager.installedModels().count) models available")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            router.push(.settingsScreen)
                        }) {
                            Image(systemName: "gearshape.fill")
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
                    
                    if modelManager.installedModels().isEmpty {
                        EmptyModelsView()
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(modelManager.installedModels()) { model in
                                    ModernModelCard(model: model, isSelected: selectedModel?.id == model.id) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedModel = selectedModel?.id == model.id ? nil : model
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
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
                
                // Configuration and recent sessions for selected model
                if let selected = selectedModel {
                    // Thread and Memory Configuration
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Configuration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.text)
                            
                            Spacer()
                            
                            Text(selected.shortDisplayName)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
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
                                        if threadNum > 1 {
                                            threadNum -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(threadNum > 1 ? .main : .gray.opacity(0.3))
                                    }
                                    .disabled(threadNum <= 1)
                                    
                                    Text("\(threadNum)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.text)
                                        .frame(minWidth: 30)
                                    
                                    Button(action: {
                                        if threadNum < cpuCount {
                                            threadNum += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(threadNum < cpuCount ? .main : .gray.opacity(0.3))
                                    }
                                    .disabled(threadNum >= cpuCount)
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
                        .padding(.horizontal, 20)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    Spacer()
                    ///  forbid history
//                    RecentSessionsView(
//                        modelName: selected.modelName,
//                        sessions: recentSessions.filter { $0.modelName == selected.modelName },
//                        onSelectSession: { session in
//                            router.push(.chatScreen(selected, session))
//                        }
//                    )
                } else {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("Select a model to start chatting")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            
            // Floating action button for new chat
            if selectedModel != nil {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Settings summary
                        HStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .font(.system(size: 14))
                            Text("\(threadNum)")
                                .font(.system(size: 14, weight: .medium))
                            
                            Divider()
                                .frame(height: 16)
                            
                            Image(systemName: "memorychip")
                                .font(.system(size: 14))
                            Text("\(memorySize)GB")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        
                        Button(action: {
                            if let model = selectedModel {
                                router.push(.chatScreen(model, nil, threadNum, memorySize))
                            }
                        }) {
                            HStack {
                                Image(systemName: "message.badge.filled.fill")
                                Text("Start Chat")
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
        }
        .navigationBarBackButtonHidden()
    }
}

struct ModernModelCard: View {
    let model: ModelInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .main)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                Text(model.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .text)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                    Text(model.formattedSize)
                        .font(.system(size: 12))
                }
                .foregroundColor(isSelected ? .white.opacity(0.9) : .gray)
            }
            .padding(16)
            .frame(width: 180, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.main, .main.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isSelected ? .main.opacity(0.3) : .black.opacity(0.05),
                        radius: isSelected ? 10 : 5,
                        x: 0,
                        y: isSelected ? 5 : 2
                    )
            )
        }
    }
}

struct RecentSessionsView: View {
    let modelName: String
    let sessions: [ChatSession]
    let onSelectSession: (ChatSession) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !sessions.isEmpty {
                    Text("Continue Conversation")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.text)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(sessions.prefix(5)) { session in
                            Button(action: {
                                onSelectSession(session)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.text)
                                            .lineLimit(1)
                                        
                                        Text("\(session.messages.count) messages")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 20)
        }
    }
}

struct EmptyModelsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No models installed")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.text)
            
            Text("Download models from settings to get started")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
}
