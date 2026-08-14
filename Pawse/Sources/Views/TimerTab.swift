import SwiftUI

/// 计时 Tab · 圆形进度环 + 时间 + 暂停/继续图标按钮
struct TimerTab: View {
    var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: timerManager.progress)
                Text(timerManager.displayTime)
                    .font(.system(size: 38, weight: .medium, design: .monospaced))
            }
            .frame(width: 180, height: 180)

            Spacer()

            // 图标按钮：暂停 / 继续
            Button(action: { timerManager.togglePause() }) {
                Image(systemName: timerManager.state == .paused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(timerManager.state == .onBreak)

            Spacer().frame(height: 16)
        }
    }

    private var progressColor: Color {
        switch timerManager.state {
        case .running: .accentColor
        case .idle: .orange
        case .paused: .secondary
        case .onBreak: .accentColor
        }
    }
}
