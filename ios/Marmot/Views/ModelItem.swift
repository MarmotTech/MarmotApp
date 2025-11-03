import SwiftUI

struct ModelItem: View {
    let modelInfo: ModelInfo
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 18) {
                Circle()
                    .fill(Color.tertiary)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "bolt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    }

                Text(modelInfo.modelName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(.plain)
    }
}
