import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @EnvironmentObject private var router: Router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("autoSaveChats") private var autoSaveChats = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("streamingResponses") private var streamingResponses = true
    
    @State private var showDeleteConfirmation = false
    @State private var showAboutSheet = false
    @State private var showClearDataConfirmation = false
    
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        router.pop()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color(UIColor.systemBackground))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance Section
                        SettingsSection(title: "Appearance") {
                            SettingsToggleRow(
                                icon: "moon.circle.fill",
                                title: "Use System Theme",
                                value: $useSystemTheme
                            )
                            
                            if !useSystemTheme {
                                SettingsToggleRow(
                                    icon: "moon.fill",
                                    title: "Dark Mode",
                                    value: $isDarkMode
                                )
                            }
                        }
                        
                        // Chat Settings
                        SettingsSection(title: "Chat Settings") {
                            SettingsToggleRow(
                                icon: "square.and.arrow.down",
                                title: "Auto-save Conversations",
                                value: $autoSaveChats
                            )
                            
                            SettingsToggleRow(
                                icon: "text.bubble",
                                title: "Streaming Responses",
                                value: $streamingResponses
                            )
                        }
                        
                        // Interaction
                        SettingsSection(title: "Interaction") {
                            SettingsToggleRow(
                                icon: "hand.tap.fill",
                                title: "Haptic Feedback",
                                value: $hapticFeedback
                            )
                        }
                        
                        // Data & Privacy
                        SettingsSection(title: "Data & Privacy") {
                            SettingsActionRow(
                                icon: "trash.fill",
                                title: "Clear All Chats",
                                color: .red,
                                action: {
                                    showClearDataConfirmation = true
                                }
                            )
                            
                            SettingsActionRow(
                                icon: "doc.text.fill",
                                title: "Export Data",
                                color: .main,
                                action: {
                                    // TODO: Implement export functionality
                                }
                            )
                            
                            SettingsActionRow(
                                icon: "lock.fill",
                                title: "Privacy Policy",
                                color: .main,
                                action: {
                                    // TODO: Open privacy policy
                                }
                            )
                        }
                        
                        // About
                        SettingsSection(title: "About") {
                            SettingsInfoRow(
                                icon: "info.circle.fill",
                                title: "Version",
                                value: "1.0.0"
                            )
                            
                            SettingsActionRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support",
                                color: .main,
                                action: {
                                    // TODO: Open help
                                }
                            )
                            
                            SettingsActionRow(
                                icon: "star.fill",
                                title: "Rate Marmot",
                                color: .main,
                                action: {
                                    // TODO: Open App Store rating
                                }
                            )
                        }
                        
                        // Footer
                        VStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .font(.system(size: 32))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Marmot")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text("On-device AI, Private & Secure")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.vertical, 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .preferredColorScheme(useSystemTheme ? nil : (isDarkMode ? .dark : .light))
        .confirmationDialog(
            "Clear All Chats",
            isPresented: $showClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearAllChats()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all chat history. This action cannot be undone.")
        }
    }
    
    private func clearAllChats() {
        do {
            try modelContext.delete(model: ChatSession.self)
            try modelContext.delete(model: ChatItem.self)
            try modelContext.save()
        } catch {
            print("Failed to clear chats: \(error)")
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var value: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.main)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $value)
                .labelsHidden()
                .tint(.main)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


struct SettingsActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.main)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}