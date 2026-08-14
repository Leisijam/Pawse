import SwiftUI
import AppKit

/// 可捕获 Esc 键的自定义容器视图
final class BreakKeyView: NSView {
    var onEsc: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEsc?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            onEsc?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// 全屏猫咪休息窗口管理器 · 透明窗口 + 猫咪浮在桌面上
@MainActor
final class BreakWindowManager {
    private var breakWindows: [NSWindow] = []
    var onBreakDismissed: (() -> Void)?

    func show(settings: AppSettings) {
        guard breakWindows.isEmpty else { return }

        for screen in NSScreen.screens {
            let screenFrame = screen.frame

            let window = NSWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.isReleasedWhenClosed = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            // 自定义容器视图处理 Esc 键
            let keyView = BreakKeyView(frame: NSRect(origin: .zero, size: screenFrame.size))
            keyView.autoresizingMask = [.width, .height]
            keyView.wantsLayer = true
            keyView.layer?.backgroundColor = .clear
            keyView.layer?.isOpaque = false
            keyView.onEsc = { [weak self] in self?.dismiss() }

            // SwiftUI 内容
            let hostingView = NSHostingView(
                rootView: BreakOverlayView(
                    onDismiss: { [weak self] in self?.dismiss() },
                    breakDurationSeconds: settings.breakDuration * 60
                )
            )
            hostingView.frame = keyView.bounds
            hostingView.autoresizingMask = [.width, .height]
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            hostingView.layer?.isOpaque = false

            keyView.addSubview(hostingView)
            window.contentView = keyView
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()

            breakWindows.append(window)
        }
    }

    func dismiss() {
        for w in breakWindows { w.orderOut(nil); w.close() }
        breakWindows.removeAll()
        onBreakDismissed?()
    }
}
