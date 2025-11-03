import AVKit
import SwiftUI

struct LoopingVideoPlayer: View {
    private var player: AVQueuePlayer
    private var playerLooper: AVPlayerLooper
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear { player.play() }
            .onDisappear{ player.pause() }
    }
    
    init(videoURL: URL) {
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        
        player = AVQueuePlayer(playerItem: item)
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
    }
}

extension AVPlayerViewController {
    open override func viewDidLoad() {
        view.backgroundColor = .white
    }
}
