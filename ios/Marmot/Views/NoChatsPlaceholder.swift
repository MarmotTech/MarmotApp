import SwiftUI

struct NoChatsPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Seems to be you didn’t\nstart any chat yet")
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryText)

            Image(.chatIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .foregroundColor(Color.main)
        }
    }
}
