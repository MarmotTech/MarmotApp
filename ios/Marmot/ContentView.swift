import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var router = Router()
    @StateObject private var modelManager = ModelManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ChatSession]
    @State private var hasCheckedSessions = false
    
    var body: some View {
        NavigationStack(
            path: $router.path,
            root: {
                RouteView(route: router.root)
                    .navigationDestination(for: Route.self) {
                        RouteView(route: $0)
                    }
            }
        )
        .environmentObject(router)
        .environmentObject(modelManager)
//        .onAppear {
//            if !hasCheckedSessions {
//                hasCheckedSessions = true
//                // Check if we have sessions and should show resume screen
//                if !sessions.isEmpty {
//                    router.replaceRoot(.resumeSessionScreen)
//                } else {
//                    router.replaceRoot(.menuScreen)
//                }
//            }
//        }
    }
}

struct RouteView: View {
    var route: Route
    
    var body: some View {
        switch (route) {
        case .welcomeScreen:
            WelcomeScreen()
        case .menuScreen:
            MenuScreen()
        case .resumeSessionScreen:
            ResumeSessionScreen()
        case .modelsScreen:
            ModelsScreen()
        case .chatScreen(let model, let session, let threadNum, let memorySize):
            ChatScreen(modelInfo: model, existingSession: session, threadNum: threadNum, memorySize: memorySize)
        case .chatHistoryScreen:
            ChatHistoryScreen()
        case .benchmarksScreen:
            BenchmarkScreen()
        case .settingsScreen:
            SettingsScreen()
        case .manageModelsScreen:
            ManageModelsScreen()
        case .modelSettingsScreen(let model):
            ModelSettingsScreen(modelInfo: model)
        }
    }
}

#Preview {
    ContentView()
}
