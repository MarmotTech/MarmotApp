import SwiftUI

struct MenuScreen: View {
    @State private var showingSheet = false
    @State private var hasCheckedModels = false
    @EnvironmentObject private var modelManager: ModelManager
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ZStack {
            // Modern gradient background
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
                // Fixed header with settings
                VStack(spacing: 0) {
                    HStack {
                        Text("Welcome to Marmot")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.main, .main.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
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
                    
                    HStack {
                        Text("Your AI assistant, running locally")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.95, blue: 1.0),
                            Color(red: 0.97, green: 0.97, blue: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 2)
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Main features - cleaner without redundancy
                        mainFeaturesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showingSheet) {
            DownloadSheet()
                .presentationDetents([.height(400)])
        }
        .task {
            ///fetch models list every time
            await modelManager.fetchModels()
            
            if !hasCheckedModels {
                hasCheckedModels = true
                // Only show sheet if no models are installed
                if modelManager.installedModels().isEmpty && !modelManager.missingModels().isEmpty {
                    showingSheet = true
                }
            }
        }
    }
    
    
    private var mainFeaturesSection: some View {
        VStack(spacing: 12) {
            ModernMenuCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Start Chatting",
                subtitle: "Choose from various AI models",
                gradient: [.main, .main.opacity(0.8)],
                action: {
                    router.push(.modelsScreen)
                }
            )
            /// forbidden history
//            ModernMenuCard(
//                icon: "clock.arrow.circlepath",
//                title: "Chat History",
//                subtitle: "View and continue conversations",
//                gradient: [.blue, .blue.opacity(0.8)],
//                action: {
//                    router.push(.chatHistoryScreen)
//                }
//            )
            
            ModernMenuCard(
                icon: "arrow.down.circle.fill",
                title: "Manage Models",
                subtitle: "Download and organize AI models",
                gradient: [.purple, .purple.opacity(0.8)],
                action: {
                    router.push(.manageModelsScreen)
                }
            )
            
            ModernMenuCard(
                icon: "speedometer",
                title: "Benchmark",
                subtitle: "Test model performance",
                gradient: [.orange, .orange.opacity(0.8)],
                action: {
                    router.push(.benchmarksScreen)
                }
            )
        }
        .padding(.bottom, 20)
    }
}

struct ModernMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: gradient[0].opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
    }
}

struct MenuScreen_Previews: PreviewProvider {
    static var previews: some View {
        MenuScreen()
    }
}
