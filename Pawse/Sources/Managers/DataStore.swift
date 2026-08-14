import Foundation
import AppKit
import AVFoundation

/// 数据持久化管理器
/// 负责文件操作：猫咪图片保存、历史记录（阶段 5）
final class DataStore {
    static let shared = DataStore()

    /// 应用支持目录 ~/Library/Application Support/Pawse/
    let appSupportDir: URL

    private init() {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        appSupportDir = base.appendingPathComponent("Pawse")
        ensureDirectoryExists(appSupportDir)
        migrateOldDataIfNeeded(base: base)
    }

    /// 从旧的 PawBreak 目录迁移数据（一次性）
    private func migrateOldDataIfNeeded(base: URL) {
        let oldDir = base.appendingPathComponent("PawBreak")
        guard FileManager.default.fileExists(atPath: oldDir.path),
              let contents = try? FileManager.default.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil) else { return }
        for file in contents {
            let dest = appSupportDir.appendingPathComponent(file.lastPathComponent)
            if !FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.copyItem(at: file, to: dest)
            }
        }
    }

    // MARK: 猫咪图片管理

    /// 将用户选择的图片复制到应用目录，返回路径
    /// - Parameter sourceURL: 用户选择的原始文件 URL
    /// - Returns: 复制后的持久化文件路径，失败返回 nil
    func saveCatImage(from sourceURL: URL) -> String? {
        let ext = sourceURL.pathExtension.lowercased()
        let destURL = appSupportDir.appendingPathComponent("customCat.\(ext)")

        // 清理旧文件（支持替换不同格式）
        cleanupOldCatFiles()

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return destURL.path
        } catch {
            print("[Pawse] 保存猫咪图片失败: \(error)")
            return nil
        }
    }

    /// 加载自定义猫咪图片
    func loadCatImage() -> NSImage? {
        // 尝试常见格式
        for ext in ["png", "jpg", "jpeg", "gif"] {
            let url = appSupportDir.appendingPathComponent("customCat.\(ext)")
            if FileManager.default.fileExists(atPath: url.path) {
                return NSImage(contentsOf: url)
            }
        }
        return nil
    }

    /// 删除所有自定义猫咪图片
    func removeCatImages() {
        cleanupOldCatFiles()
    }

    // MARK: 猫咪视频管理

    /// 猫咪视频存储路径
    var catVideoPath: URL {
        appSupportDir.appendingPathComponent("cat.mov")
    }

    /// 获取猫咪视频 URL（首次启动自动用内置默认视频初始化）
    func catVideoURL() -> URL? {
        let alphaURL = appSupportDir.appendingPathComponent("cat_alpha.mov")
        if FileManager.default.fileExists(atPath: alphaURL.path) { return alphaURL }

        // 首次运行：从 app 内置资源复制默认视频
        if let bundled = Bundle.module.url(forResource: "DefaultCat", withExtension: "mov") {
            try? FileManager.default.copyItem(at: bundled, to: alphaURL)
            return alphaURL
        }

        let url = catVideoPath
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// 预加载好的猫咪视频资源（休息弹窗直接用它构建播放器，避免临出现时才解析视频导致的延迟）
    private(set) var preloadedVideoAsset: AVURLAsset?

    /// 提前异步加载视频资源。应在应用启动、以及用户更换/恢复猫咪视频后调用
    func preloadCatVideo() {
        guard let url = catVideoURL() else { preloadedVideoAsset = nil; return }
        let asset = AVURLAsset(url: url)
        preloadedVideoAsset = asset
        Task.detached(priority: .utility) {
            _ = try? await asset.load(.tracks, .duration, .isPlayable)
        }
    }

    /// 用户是否上传了自定义视频
    var hasCustomCatVideo: Bool {
        UserDefaults.standard.bool(forKey: "hasCustomCatVideo")
    }

    /// 保存用户上传的猫咪视频
    /// - Parameter sourceURL: 视频源文件 URL
    /// - Returns: 保存成功返回目标路径，失败返回 nil
    func saveCatVideo(from sourceURL: URL) -> String? {
        let destURL = appSupportDir.appendingPathComponent("cat_alpha.mov")
        ensureDirectoryExists(appSupportDir)

        if FileManager.default.fileExists(atPath: destURL.path) {
            try? FileManager.default.removeItem(at: destURL)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            UserDefaults.standard.set(true, forKey: "hasCustomCatVideo")
            return destURL.path
        } catch {
            print("[Pawse] 保存猫咪视频失败: \(error)")
            return nil
        }
    }

    /// 恢复默认猫咪视频（从 app 内置资源恢复，不依赖外部路径）
    func removeCatVideo() {
        let alphaURL = appSupportDir.appendingPathComponent("cat_alpha.mov")
        try? FileManager.default.removeItem(at: alphaURL)

        if let bundled = Bundle.module.url(forResource: "DefaultCat", withExtension: "mov") {
            try? FileManager.default.copyItem(at: bundled, to: alphaURL)
        }
        UserDefaults.standard.set(false, forKey: "hasCustomCatVideo")
    }

    // MARK: 头像管理

    private var avatarURL: URL {
        appSupportDir.appendingPathComponent("avatar.png")
    }

    func saveAvatar(from sourceURL: URL) -> String? {
        let dest = avatarURL
        if FileManager.default.fileExists(atPath: dest.path) {
            try? FileManager.default.removeItem(at: dest)
        }
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dest)
            return dest.path
        } catch {
            print("[Pawse] 保存头像失败: \(error)")
            return nil
        }
    }

    func loadAvatar() -> NSImage? {
        let url = avatarURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }

    // MARK: 历史记录

    /// 历史记录文件路径
    var recordsURL: URL {
        appSupportDir.appendingPathComponent("records.json")
    }

    /// 加载所有历史记录
    func loadAllRecords() -> [DailyRecord] {
        guard FileManager.default.fileExists(atPath: recordsURL.path),
              let data = try? Data(contentsOf: recordsURL) else {
            return []
        }
        return (try? JSONDecoder().decode([DailyRecord].self, from: data)) ?? []
    }

    /// 保存或更新今日记录
    func saveTodayRecord(_ record: DailyRecord) {
        var records = loadAllRecords()
        if let index = records.firstIndex(where: { $0.dateString == record.dateString }) {
            records[index] = record
        } else {
            records.append(record)
        }
        // 只保留最近 90 天
        if records.count > 90 {
            records = Array(records.suffix(90))
        }
        if let data = try? JSONEncoder().encode(records) {
            try? data.write(to: recordsURL)
        }
    }

    /// 读取今日记录
    func loadTodayRecord() -> DailyRecord {
        let records = loadAllRecords()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return records.first(where: { $0.dateString == today }) ?? DailyRecord.today()
    }

    // MARK: 内部

    private func ensureDirectoryExists(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(
                at: url, withIntermediateDirectories: true
            )
        }
    }

    private func cleanupOldCatFiles() {
        for ext in ["png", "jpg", "jpeg", "gif"] {
            let url = appSupportDir.appendingPathComponent("customCat.\(ext)")
            try? FileManager.default.removeItem(at: url)
        }
    }
}
