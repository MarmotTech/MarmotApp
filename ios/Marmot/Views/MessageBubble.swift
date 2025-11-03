import SwiftUI

struct MessageBubble: View {
    let message: ChatItem
    @State private var showCopyMenu = false
    
    var body: some View {
        HStack {
            if message.type == .userMessage {
                Spacer()
                userMessageBubble
            } else {
                botMessageBubble
                Spacer()
            }
        }
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = message.text
            }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.main)
                .foregroundColor(.white)
                .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                .frame(maxWidth: 280, alignment: .trailing)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondaryText)
                .padding(.trailing, 8)
        }
    }
    
    private var botMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.tertiary)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                
                Text(message.text.isEmpty ? "..." : message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
                    .frame(maxWidth: 280, alignment: .leading)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
            }
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondaryText)
                .padding(.leading, 40)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(message: ChatItem(type: .userMessage, text: "Hello, how are you today?"))
        MessageBubble(message: ChatItem(type: .botMessage, text: "I'm doing well, thank you for asking! How can I help you today?"))
        MessageBubble(message: ChatItem(type: .botMessage, text: ""))
    }
    .padding()
    .background(Color.tertiary)
}