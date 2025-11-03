import SwiftUI

struct WelcomeScreen: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var modelManager: ModelManager
    
    var body: some View {
        VStack {
            Color.clear
                .background {
                    Image(.globeBackground)
                        .resizable()
                        .scaledToFill()
                        .frame(minHeight: 0, maxHeight: .infinity)
                        .clipped()
                }
                .overlay(alignment: .top) {
                    GlobeView()
                }
                .overlay(alignment: .top) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(.chatIcon)

                        Text("MARMOT")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(.white)
                    .padding(safeAreaInsets)
                }
            
            VStack(spacing: 0) {
                Text("Chat with AI,\nPrivacy-First solution")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.text)
                
                Text("A powerful language model running locally on your device, dare to try it?")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.top, 13)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(height: 83)
                
                SwipeToStart(
                    onComplete: {
                        router.replaceRoot(.menuScreen)
                    }
                )
                .disabled(modelManager.models.isEmpty)
            }
            .padding(.top, 37)
            .padding(.horizontal, 37)
            .padding(.bottom, 42)
            .fixedSize(horizontal: false, vertical: true)
        }
        .ignoresSafeArea()
        .background(.white)
        .task {
            await modelManager.fetchModels()
        }
    }
}

#Preview {
    WelcomeScreen()
}
