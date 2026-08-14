import SwiftUI
import ServiceManagement

@main
struct PawseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - 自定义菜单项视图（承载 SwiftUI 内容）

final class MenuItemView: NSView {
    let hostingView: NSHostingView<AnyView>

    init(rootView: some View) {
        hostingView = NSHostingView(rootView: AnyView(rootView))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        super.init(frame: hostingView.frame)
        addSubview(hostingView)
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    private let timerManager = TimerManager(settings: AppSettings())
    private let breakWindowManager = BreakWindowManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupTimerCallbacks()
        setupBreakWindowCallback()
        setupAutoLaunch()
        DataStore.shared.preloadCatVideo()
        timerManager.start()
    }

    private func setupAutoLaunch() {
        do {
            if timerManager.settings.launchAtLogin {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("[Pawse] 开机自启注册失败: \(error)")
        }
    }

    // MARK: 菜单栏 + NSMenu（标准做法，顶栏不会隐藏）

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = timerManager.displayTime
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }

        // 用 NSMenu + 自定义 NSView 替代 NSPopover
        let menu = NSMenu()
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.view = MenuItemView(rootView: MenuBarView(timerManager: timerManager)
            .frame(width: 400, height: 400))
        menu.addItem(item)
        statusItem.menu = menu
    }

    // MARK: 回调

    private func setupTimerCallbacks() {
        timerManager.onDisplayTimeChanged = { [weak self] title in
            DispatchQueue.main.async {
                self?.statusItem.button?.title = title
            }
        }
        timerManager.onBreakTriggered = { [weak self] in
            DispatchQueue.main.async {
                self?.breakWindowManager.show(settings: self?.timerManager.settings ?? AppSettings())
            }
        }
    }

    private func setupBreakWindowCallback() {
        breakWindowManager.onBreakDismissed = { [weak self] in
            self?.timerManager.skipBreak()
        }
    }
}
