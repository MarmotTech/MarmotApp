import SwiftUI
import SwiftData

struct ChatHistoryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var modelManager: ModelManager
    
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var sessions: [ChatSession]
    
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var sessionToDelete: ChatSession?
    
    var filteredSessions: [ChatSession] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { session in
            session.title.localizedCaseInsensitiveContains(searchText) ||
            session.messages.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern header
                headerView
                
                if sessions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                ChatHistoryCard(session: session)
                                    .onTapGesture {
                                        navigateToChat(session)
                                    }
                                    .contextMenu {
                                        Button(action: {
                                            navigateToChat(session)
                                        }) {
                                            Label("Continue Chat", systemImage: "bubble.left.and.bubble.right")
                                        }
                                        
                                        Button(action: {
                                            duplicateSession(session)
                                        }) {
                                            Label("Duplicate", systemImage: "doc.on.doc")
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            sessionToDelete = session
                                            showDeleteConfirmation = true
                                        }) {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        // Refresh action if needed
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .confirmationDialog(
            "Delete Chat",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This conversation will be permanently deleted.")
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    router.pop()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.text)
                }
                
                Spacer()
                
                Text("Chat History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.text)
                
                Spacer()
                
                Button(action: {
                    // Add new chat action
                    router.push(.modelsScreen)
                }) {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.main)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Modern search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search conversations...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.text)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
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
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No Conversations Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.text)
            
            Text("Start a new chat to see your history here")
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                router.push(.modelsScreen)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Start New Chat")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.main, .main.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .main.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func navigateToChat(_ session: ChatSession) {
        guard let modelInfo = session.modelInfo ?? modelManager.models.first(where: { $0.modelName == session.modelName }) else {
            return
        }
        router.push(.chatScreen(modelInfo, session))
    }
    
    private func deleteSession(_ session: ChatSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    private func duplicateSession(_ session: ChatSession) {
        let newSession = ChatSession(
            title: "\(session.title) (Copy)",
            modelName: session.modelName,
            modelInfo: session.modelInfo
        )
        
        for message in session.sortedMessages {
            let newMessage = ChatItem(
                type: message.type,
                text: message.text,
                timestamp: message.timestamp
            )
            newSession.addMessage(newMessage)
        }
        
        modelContext.insert(newSession)
        try? modelContext.save()
    }
}

struct ChatHistoryCard: View {
    let session: ChatSession
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.lastMessageAt, relativeTo: Date())
    }
    
    private var lastMessage: String {
        session.sortedMessages.last?.text ?? "No messages"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Model icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.main.opacity(0.8), .main]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "cpu")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.text)
                        .lineLimit(1)
                    
                    HStack {
                        Text(session.modelName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                        
                        Text("•")
                            .foregroundColor(.secondaryText)
                        
                        Text(timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.secondaryText)
                    }
                }
                
                Spacer()
                
                // Message count badge
                Text("\(session.messages.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                    )
            }
            
            Text(lastMessage)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
                .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    ChatHistoryScreen()
        .environmentObject(Router())
        .environmentObject(ModelManager())
}