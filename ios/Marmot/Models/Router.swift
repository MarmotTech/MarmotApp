import Foundation

class Router: ObservableObject {
    @Published var path: [Route] = []
    @Published var root: Route = .menuScreen
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func replaceRoot(_ route: Route) {
        root = route
    }
}

enum Route: Hashable {
    case welcomeScreen
    case menuScreen
    case resumeSessionScreen
    case modelsScreen
    case chatScreen(ModelInfo, ChatSession? = nil, Int = 2, Float = 2)
    case chatHistoryScreen
    case benchmarksScreen
    case settingsScreen
    case manageModelsScreen
    case modelSettingsScreen(ModelInfo)
}
