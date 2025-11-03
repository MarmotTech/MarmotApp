import SwiftUI
import SwiftData

struct ResumeSessionScreen: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var modelManager: ModelManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse) private var sessions: [ChatSession]
    
    private var lastSession: ChatSession? {
        sessions.first
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon and title
                VStack(spacing: 24) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.main, .main.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("Welcome Back!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.text)
                        
                        if let lastSession = lastSession {
                            Text("Continue your conversation")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            // Last session info
                            VStack(spacing: 4) {
                                Text(lastSession.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.text.opacity(0.8))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                
                                Text(lastSession.modelName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if let lastSession = lastSession {
                        // Resume button
                        Button(action: {
                            resumeSession(lastSession)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                Text("Resume Session")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.main, .main.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .main.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // New session button
                        Button(action: {
                            startNewSession()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("New Session")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.main)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.main.opacity(0.3), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // Skip button
                        Button(action: {
                            skipToMainMenu()
                        }) {
                            Text("Skip to Main Menu")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .underline()
                        }
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func resumeSession(_ session: ChatSession) {
        // Navigate to chat with the last session
        if let modelInfo = session.modelInfo {
            router.push(.chatScreen(modelInfo, session))
        } else {
            // If no model info, go to models screen
            router.push(.modelsScreen)
        }
    }
    
    private func startNewSession() {
        // Navigate to models screen to start a new chat
        router.push(.modelsScreen)
    }
    
    private func skipToMainMenu() {
        // Navigate to main menu
        router.push(.menuScreen)
    }
}

struct ResumeSessionScreen_Previews: PreviewProvider {
    static var previews: some View {
        ResumeSessionScreen()
    }
}