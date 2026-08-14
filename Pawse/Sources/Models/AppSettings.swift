import SwiftUI

/// 应用设置模型
/// 存储于 UserDefaults，修改时自动同步
@Observable
final class AppSettings {
    /// 工作时长（分钟），默认 40
    var workDuration: Int { didSet { save() } }
    /// 休息时长（分钟），默认 5
    var breakDuration: Int { didSet { save() } }
    /// 无操作判定时间（秒），默认 120（2 分钟）
    var idleTimeout: Int { didSet { save() } }
    /// 是否开启免打扰
    var isDNDEnabled: Bool { didSet { save() } }
    /// 自定义猫咪图片路径（nil = 默认动画）
    var customCatPath: String? { didSet { save() } }
    /// 是否开机自启
    var launchAtLogin: Bool { didSet { save() } }
    /// 休息提醒自定义文字
    var breakMessage: String { didSet { save() } }

    init() {
        let defaults = UserDefaults.standard
        self.workDuration = defaults.integer(forKey: "workDuration") != 0
            ? defaults.integer(forKey: "workDuration") : 40
        self.breakDuration = defaults.integer(forKey: "breakDuration") != 0
            ? defaults.integer(forKey: "breakDuration") : 5
        self.idleTimeout = defaults.integer(forKey: "idleTimeout") != 0
            ? defaults.integer(forKey: "idleTimeout") : 120
        self.isDNDEnabled = defaults.bool(forKey: "isDNDEnabled")
        self.customCatPath = defaults.string(forKey: "customCatPath")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.breakMessage = defaults.string(forKey: "breakMessage") ?? "该休息一下了 🐱"
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(workDuration, forKey: "workDuration")
        defaults.set(breakDuration, forKey: "breakDuration")
        defaults.set(idleTimeout, forKey: "idleTimeout")
        defaults.set(isDNDEnabled, forKey: "isDNDEnabled")
        if let path = customCatPath {
            defaults.set(path, forKey: "customCatPath")
        } else {
            defaults.removeObject(forKey: "customCatPath")
        }
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(breakMessage, forKey: "breakMessage")
    }
}
