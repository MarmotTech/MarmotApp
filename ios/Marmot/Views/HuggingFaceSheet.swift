import Combine
import SwiftUI

struct RepoModel: Codable {
    let id: String
    let downloads: Int
}

class SearchManager: ObservableObject {
    @Published var searchText: String = ""
    @Published var repos: [RepoModel] = []

    var subscription: Set<AnyCancellable> = []

    init() {
        $searchText
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { text -> AnyPublisher<[RepoModel], Never> in
                guard !text.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                var searchUrl = URL(string: "https://huggingface.co/api/models")
                searchUrl?.append(queryItems: [
                    URLQueryItem(name: "filter", value: "gguf"),
                    URLQueryItem(name: "search", value: text),
                ])

                return URLSession.shared.dataTaskPublisher(for: searchUrl!)
                    .map(\.data)
                    .decode(type: [RepoModel].self, decoder: JSONDecoder())
                    .replaceError(with: [])
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .assign(to: &$repos)
    }
}

struct HuggingFaceSheet: View {
    @StateObject var manager: SearchManager = .init()

    @State var importInQueue: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            if importInQueue {
                VStack(spacing: 8) {
                    Text("Import in Progress...")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.text)

                    Text(
                        "We’ll let you know once the import to our servers is complete. You can close this now and continue using the app."
                    )
                    .font(.caption)
                    .foregroundColor(Color.secondaryText)

                    Spacer()
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.text)

                    TextField(
                        "",
                        text: $manager.searchText,
                        prompt: Text("Search").foregroundColor(.secondaryText)
                    )
                    .foregroundStyle(.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .autocorrectionDisabled()
                }
                .padding(16)
                .background(Color.tertiary)
                .cornerRadius(24)

                ScrollView {
                    LazyVStack {
                        ForEach(Array(manager.repos.enumerated()), id: \.1.id) { offset, repo in
                            let parts = repo.id.split(separator: "/")
                            let author = parts.first ?? ""
                            let name = parts.last ?? ""

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(author)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondaryText)

                                    Text(name)

                                    (Text(Image(systemName: "arrow.down.to.line"))
                                        .baselineOffset(1) + Text(" \(repo.downloads)"))
                                        .font(.caption)
                                        .foregroundStyle(Color.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    importInQueue.toggle()
                                }) {
                                    Text("Import")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .frame(height: 36)
                                        .background(.main)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .foregroundStyle(.text)
                            .padding(8)

                            if offset != manager.repos.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .ignoresSafeArea()
        .presentationBackground(Color.white)
        .presentationDetents(importInQueue ? [.height(250)] : [])
    }
}

#Preview {
    HuggingFaceSheet()
}
