import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement
import AppKit

/// 设置 Tab
struct SettingsTab: View {
    var settings: AppSettings
    @State private var isCustomVideo: Bool = false
    @State private var showSuccess = false
    @State private var showRestored = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                settingRow(icon: "clock", title: "工作时长") {
                    numField(Binding(get: { settings.workDuration },
                                     set: { settings.workDuration = clamp($0, 1, 480) }))
                    Text("分钟").font(.caption).foregroundColor(.secondary)
                }
                Divider()
                settingRow(icon: "figure.walk", title: "休息时长") {
                    numField(Binding(get: { settings.breakDuration },
                                     set: { settings.breakDuration = clamp($0, 1, 60) }))
                    Text("分钟").font(.caption).foregroundColor(.secondary)
                }
                Divider()
                settingRow(icon: "hand.raised.fill", title: "空闲判定") {
                    numField(Binding(get: { settings.idleTimeout / 60 },
                                     set: { settings.idleTimeout = clamp($0 * 60, 60, 3600) }))
                    Text("分钟").font(.caption).foregroundColor(.secondary)
                }
                Divider()
                settingRow(icon: "moon.zzz.fill", title: "免打扰") {
                    Toggle("", isOn: Binding(get: { settings.isDNDEnabled },
                                              set: { settings.isDNDEnabled = $0 }))
                        .toggleStyle(.switch).labelsHidden()
                }
                Divider()
                settingRow(icon: "power", title: "开机自启") {
                    Toggle("", isOn: Binding(get: { settings.launchAtLogin }, set: { e in
                        settings.launchAtLogin = e
                        do { if e { try SMAppService.mainApp.register() }
                              else { try SMAppService.mainApp.unregister() } }
                        catch { print("[Pawse] 开机自启失败: \(error)") }
                    })).toggleStyle(.switch).labelsHidden()
                }
                Divider()
                settingRow(icon: "cat.fill", title: "休息动画") {
                    HStack(spacing: 8) {
                        if showSuccess {
                            Label("已上传", systemImage: "checkmark.circle.fill")
                                .font(.caption).foregroundColor(.green)
                        }
                        if showRestored {
                            Label("已恢复", systemImage: "checkmark.circle.fill")
                                .font(.caption).foregroundColor(.green)
                        }
                        Button("选择视频...") { pickVideo() }
                            .buttonStyle(.borderless).font(.caption)
                        Button("恢复默认") { restoreDefault() }
                            .buttonStyle(.borderless).font(.caption)
                            .foregroundColor(isCustomVideo ? .red : .secondary)
                            .disabled(!isCustomVideo)
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            isCustomVideo = DataStore.shared.hasCustomCatVideo
        }
    }

    // MARK: 视频选择（独立可移动窗口，不遮挡/误触 popover）

    private func pickVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .quickTimeMovie, .mpeg4Movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "选择休息动画视频"

        // 菜单栏应用（LSUIElement）默认不能成为前台应用，
        // 文件选择框会弹到其它窗口后面。临时切换为普通应用并激活，
        // 选择框关闭后再恢复为菜单栏应用。
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        panel.begin { response in
            // 无论选择还是取消，都恢复为菜单栏应用策略
            NSApp.setActivationPolicy(.accessory)

            guard response == .OK, let url = panel.url else { return }
            if DataStore.shared.saveCatVideo(from: url) != nil {
                DataStore.shared.preloadCatVideo()
                isCustomVideo = true
                showSuccess = true
                showRestored = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSuccess = false }
            }
        }
    }

    private func restoreDefault() {
        DataStore.shared.removeCatVideo()
        DataStore.shared.preloadCatVideo()
        isCustomVideo = false
        showRestored = true
        showSuccess = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showRestored = false }
    }

    // MARK: 对齐行

    private func settingRow<C: View>(icon: String, title: String, @ViewBuilder content: () -> C) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.body).foregroundColor(.secondary).frame(width: 18)
            Text(title).font(.body)
            Spacer()
            content()
        }
    }

    private func numField(_ value: Binding<Int>) -> some View {
        TextField("", value: value, format: .number)
            .textFieldStyle(.roundedBorder).frame(width: 56)
            .font(.caption).multilineTextAlignment(.trailing)
    }

    private func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { Swift.max(lo, Swift.min(hi, v)) }
}
