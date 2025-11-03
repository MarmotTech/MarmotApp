import SwiftUI

struct AsymmetricCutCornerShape: Shape {
    let cornerRadius: CGFloat
    let innerCornerRadius: CGFloat
    let cutCornerHeight: CGFloat
    let cutCornerWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(360),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cutCornerHeight - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cutCornerHeight - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.width - cutCornerWidth + innerCornerRadius, y: rect.height - cutCornerHeight))
        path.addArc(
            center: CGPoint(x: rect.width - cutCornerWidth + innerCornerRadius, y: rect.height - cutCornerHeight + innerCornerRadius),
            radius: innerCornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.width - cutCornerWidth, y: rect.height - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cutCornerWidth - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.closeSubpath()

        return path
    }
}

struct MenuCard: View {
    let title: String
    let description: String
    let buttonText: String
    let containerColor: Color
    let buttonColor: Color
    let buttonTextColor: Color
    let action: () -> Void

    @State private var cutCornerWidth: CGFloat = 140
    @State private var cutCornerHeight: CGFloat = 68

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                    .lineLimit(nil)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(containerColor)
            .clipShape(
                AsymmetricCutCornerShape(
                    cornerRadius: 24,
                    innerCornerRadius: 36,
                    cutCornerHeight: cutCornerHeight,
                    cutCornerWidth: cutCornerWidth
                )
            )

            Button(action: action) {
                Text(buttonText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(buttonTextColor)
                    .padding(.horizontal, 24)
                    .frame(height: 54)
                    .background(buttonColor)
                    .cornerRadius(24)
            }
            .buttonStyle(.plain)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            cutCornerWidth = geo.size.width + 12
                            cutCornerHeight = geo.size.height + 12
                        }
                }
            )
        }
    }
}

struct MenuCard_Previews: PreviewProvider {
    static var previews: some View {
        MenuCard(
            title: "Start Message With any popular LLM you want",
            description: "Ask anything and LLM will be ready to proceed locally and answer you",
            buttonText: "Start Benchmarking",
            containerColor: Color.blue,
            buttonColor: Color.green,
            buttonTextColor: Color.white
        ) {}
    }
}
