import SwiftUI

struct SwipeToStart: View {
    var onComplete: (() -> Void)
    
    var body: some View {
        GeometryReader { geometry in
            SwipeToStart_Inner(
                maxOffset: geometry.size.width - 84,
                onComplete: onComplete
            )
        }
        .frame(height: 84)
    }
}

fileprivate struct SwipeToStart_Inner: View {
    var maxOffset: CGFloat
    var minOffset: CGFloat = 0
    
    var onComplete: (() -> Void)
    
    @State var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(
                cornerSize: CGSize(width: 84, height: 84)
            )
            .fill(Color.main)
            .frame(height: 84)
            .frame(maxWidth: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width > 0 {
                            offset = min(
                                max(value.translation.width, minOffset),
                                maxOffset
                            )
                        }
                    }
                    .onEnded { value in
                        let finalValue = value.translation.width + value.velocity.width
                        
                        if finalValue > maxOffset / 2 {
                            let duration = min(
                                0.25,
                                (maxOffset - value.translation.width) / value.velocity.width
                            )
                            
                            withAnimation(.easeOut(duration: duration)) {
                                offset = maxOffset
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                onComplete()
                            }
                        } else {
                            withAnimation(.easeInOut) {
                                offset = minOffset
                            }
                        }
                    }
            )
            
            Circle()
                .fill(.white)
                .overlay {
                    Image(.doubleRight)
                        .resizable()
                        .frame(width: 34, height: 34)
                        .foregroundStyle(Color.main)
                }
                .padding(6)
                .frame(width: 84, height: 84)
                .offset(x: offset)
                .allowsHitTesting(false)
            
            Text("Swipe to start...")
                .foregroundStyle(.white)
                .font(.system(size: 18))
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(
                    1.0 - (offset / maxOffset)
                )
        }
    }
}

#Preview {
    SwipeToStart(
        onComplete: {}
    )
    .padding()
}
