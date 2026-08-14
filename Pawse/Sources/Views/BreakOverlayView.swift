import SwiftUI
import AVFoundation
import AppKit

// MARK: - 视频渲染器（AVPlayerLayer 硬件加速，流畅不卡顿）

final class VideoPlayerView: NSView {
    private let player: AVPlayer
    private let playerLayer = AVPlayerLayer()

    init(asset: AVURLAsset) {
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        super.init(frame: .zero)

        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = .clear
        layer?.isOpaque = false

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = .clear
        playerLayer.isOpaque = false
        layer?.addSublayer(playerLayer)

        player.isMuted = true
        player.play()
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

// MARK: - SwiftUI 桥接

struct CatVideoView: NSViewRepresentable {
    let asset: AVURLAsset
    func makeNSView(context: Context) -> NSView { VideoPlayerView(asset: asset) }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - 休息覆盖层

struct BreakOverlayView: View {
    let onDismiss: () -> Void
    let breakDurationSeconds: Int
    @State private var remaining: Int
    @Environment(\.colorScheme) private var colorScheme

    private var progress: Double {
        guard breakDurationSeconds > 0 else { return 1 }
        return Double(breakDurationSeconds - remaining) / Double(breakDurationSeconds)
    }
    private var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    init(onDismiss: @escaping () -> Void, breakDurationSeconds: Int) {
        self.onDismiss = onDismiss
        self.breakDurationSeconds = breakDurationSeconds
        _remaining = State(initialValue: breakDurationSeconds)
    }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // 猫咪视频（aspectFit 全屏显示，保持原始比例）
            // 优先用预加载好的 asset，避免弹窗出现那一刻才开始解析视频造成的延迟
            if let asset = DataStore.shared.preloadedVideoAsset ?? DataStore.shared.catVideoURL().map(AVURLAsset.init(url:)) {
                CatVideoView(asset: asset).ignoresSafeArea().allowsHitTesting(false)
            } else if let img = DataStore.shared.loadCatImage() {
                Image(nsImage: img).resizable().interpolation(.high)
                    .aspectRatio(contentMode: .fit).ignoresSafeArea().allowsHitTesting(false)
            }

            // 左上角大倒计时
            VStack {
                HStack {
                    countdownRing.padding(.top, 50).padding(.leading, 50)
                    Spacer()
                }
                Spacer()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if remaining > 0 { remaining -= 1 } else { onDismiss() }
        }
    }

    private var countdownRing: some View {
        let isDark = colorScheme == .dark
        let textColor: Color = isDark ? .white : .black
        let ringColor: Color = isDark ? .white : .black

        return ZStack {
            Circle().fill(isDark ? .ultraThinMaterial : .regularMaterial)
                .frame(width: 120, height: 120)
                .shadow(color: .black.opacity(isDark ? 0.4 : 0.15), radius: 14)
            Circle().stroke(ringColor.opacity(0.2), lineWidth: 5).frame(width: 106, height: 106)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 106, height: 106).rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)
                Text("跳过休息")
                    .font(.system(size: 11)).foregroundColor(textColor.opacity(0.6))
            }
        }
        .frame(width: 120, height: 120)
        .contentShape(Circle())
        .onTapGesture { onDismiss() }
    }
}
