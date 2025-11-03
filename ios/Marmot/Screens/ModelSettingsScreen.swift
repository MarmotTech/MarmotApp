import SwiftUI

struct ModelSettingsScreen: View {
    let modelInfo: ModelInfo

    @State var threadNum: Int = 2
    @State var memorySize: Int = 2

    let cpuCount: Int = 4
    let maxMemory: Int = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.tertiary)
                        .frame(width: 64, height: 64)

                    Image(systemName: "bolt.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.white)
                }

                Text(modelInfo.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.white
                    .ignoresSafeArea()
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.text)
                    .padding(.vertical, 8)

                SettingsNumRow(
                    text: "Threads Limit",
                    iconName: "cpu",
                    value: $threadNum,
                    range: 2...cpuCount
                )

                SettingsNumRow(
                    text: "Memory Limit",
                    iconName: "memorychip",
                    value: $memorySize,
                    range: 1...maxMemory
                )

                Spacer()
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .leading)
            .background {
                Color.tertiary.ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct SettingsNumRow: View {
    let text: String
    let iconName: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            Text(text)
                .font(.body)

            Spacer()

            Button(action: {
                if value > range.lowerBound {
                    value -= 1
                }
            }) {
                Image(systemName: "minus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }

            Text("\(value)")
                .font(.body)
                .frame(width: 40, alignment: .center)

            Button(action: {
                if value < range.upperBound {
                    value += 1
                }
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
        }
        .foregroundStyle(Color.text)
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
    }
}
