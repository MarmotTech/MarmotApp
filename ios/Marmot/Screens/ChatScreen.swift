import SwiftUI
import SwiftData

struct ChatScreen: View {
    @StateObject private var llama = Llama()
    
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject private var router: Router
    
    @State private var textValue: String = ""

    let modelInfo: ModelInfo
    let existingSession: ChatSession?
    let threadNum: Int
    let memorySize: Float
    
    init(modelInfo: ModelInfo, existingSession: ChatSession? = nil, threadNum: Int = 2, memorySize: Float = 2) {
        self.modelInfo = modelInfo
        self.existingSession = existingSession
        self.threadNum = threadNum
        self.memorySize = Float(memorySize)
    }

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
            
            ZStack(alignment: .bottom) {
                if llama.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading model...")
                            .foregroundColor(.text)
                        Spacer()
                    }
                } else if let errorMessage = llama.errorMessage {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .foregroundColor(.text)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Dismiss") {
                            llama.clearError()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.main)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(llama.messages) { item in
                                    MessageBubble(message: item)
                                        .id(item.id)
                                }
                            }
                        }
                        .onAppear {
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                   if let lastMessage = llama.messages.last {
                                       withAnimation(.easeOut(duration: 0.3)) {
                                           proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                       }
                                   }
                               }
                           }
                        .onChange(of: llama.messages.count) { oldValue, newValue in
                               if let lastMessage = llama.messages.last {
                                   DispatchQueue.main.async {
                                       proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                   }
                               }
                           }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                
                VStack(spacing: 0) {
                    if llama.isGenerating {
                        HStack {
                            HStack(spacing: 6) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(.main)
                                        .frame(width: 4, height: 4)
                                        .opacity(0.4)
                                        .animation(.easeInOut(duration: 0.8).repeatForever().delay(Double(index) * 0.2), value: llama.isGenerating)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Text("AI is typing...")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("", text: $textValue, prompt: Text("Type message...").foregroundStyle(Color.secondaryText))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(24)
                            .foregroundStyle(Color.text)
                            .disabled(llama.isGenerating)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        
                        Button(action: {
                            let messageToSend = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !messageToSend.isEmpty else { return }
                            
                            llama.sendMessage(messageToSend)
                            textValue = ""
                        }) {
                            Image(systemName: llama.isGenerating ? "stop.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !llama.isGenerating ? .gray : .main)
                        }
                        .disabled(textValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !llama.isGenerating)
                    }
                    .padding(.horizontal, 16)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 10)
                .padding(16)
            }
            .background(
                Color.tertiary
                    .ignoresSafeArea()
            )
        }
        .task {
            llama.start(modelInfo: modelInfo, modelContext: modelContext, existingSession: existingSession, threadNum: threadNum, memorySize: memorySize)
        }
        .onDisappear {
            llama.stopChatSf()
        }
        .navigationBarBackButtonHidden()
    }
}
