import SwiftUI
import SwiftData


@main
struct MarmotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [BenchmarkResult.self, ChatSession.self, ChatItem.self])
    }
}

extension MarmotApp {
    static func makeContainer() -> ModelContainer {
        // 把所有模型放到数组中
        let allModels: [any PersistentModel.Type] = [
            BenchmarkResult.self,
            ChatSession.self,
            ChatItem.self
        ]
        
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        
        do {
            // ✅ 用 ModelContainer.Schema 初始化
            let schema = Schema(allModels)
            let container = try ModelContainer(for: schema, configurations: config)
            return container
        } catch {
            ///⚠️ SwiftData 数据库加载失败  删除旧数据库
            
            if let storeURL = defaultStoreURL() {
                try? FileManager.default.removeItem(at: storeURL)
                /// 已删除旧数据库
            }
            
            do {
                ///重建新的 SwiftData 数据库
                let schema = Schema(allModels)
                let newContainer = try ModelContainer(for: schema, configurations: config)
                return newContainer
            } catch {
                ///❌ 数据库重建失败，删除app吧
                fatalError("❌ 数据库重建失败: \(error)")
            }
        }
    }
    
    static func defaultStoreURL() -> URL? {
        do {
            let baseURL = try FileManager.default.url(for: .applicationSupportDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true)
            return baseURL.appendingPathComponent("default.store")
        } catch {
            print("⚠️ 无法获取数据库路径：\(error)")
            return nil
        }
    }
}
