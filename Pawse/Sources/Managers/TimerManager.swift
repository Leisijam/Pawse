import SwiftUI

/// 计时器状态
enum TimerState {
    case running      // 正在计时
    case paused       // 用户手动暂停
    case idle         // 检测到用户离开（无操作）
    case onBreak      // 休息时间（猫咪已弹出）
}

/// 计时核心管理器
/// 统管计时、活动检测、休息触发、数据记录、菜单栏更新
@Observable
final class TimerManager {
    // MARK: 公开状态

    private(set) var state: TimerState = .running
    private(set) var elapsedSeconds: Int = 0
    private(set) var todayBreakCount: Int = 0
    /// 今日累计活跃时长（秒）
    private(set) var todayActiveSeconds: Int = 0

    // MARK: 依赖

    let settings: AppSettings
    private let activityMonitor = ActivityMonitor()

    // MARK: 内部

    private var tickTimer: Timer?
    private var saveTimer: Int = 0  // tick 计数器，每 60 次保存一次记录
    private var wasDNDEnabled: Bool
    private var lastBreakTriggeredAt: Date?
    private var lastDate: String = ""

    // MARK: 回调

    var onDisplayTimeChanged: ((String) -> Void)?
    var onBreakTriggered: (() -> Void)?

    // MARK: 初始化

    init(settings: AppSettings) {
        self.settings = settings
        self.wasDNDEnabled = settings.isDNDEnabled

        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        self.lastDate = fmt.string(from: Date())

        // 恢复今日已有数据
        let today = DataStore.shared.loadTodayRecord()
        self.todayActiveSeconds = today.totalScreenTime
        self.todayBreakCount = today.breakCount
    }

    // MARK: 计算属性

    var remainingSeconds: Int {
        max(0, settings.workDuration * 60 - elapsedSeconds)
    }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard settings.workDuration > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(settings.workDuration * 60))
    }

    // MARK: 控制

    func start() {
        activityMonitor.start()

        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let timer = tickTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func pause() {
        state = .paused
        saveRecord()
        updateMenuBar()
    }

    func resume() {
        state = .running
        activityMonitor.resetActivity()
        updateMenuBar()
    }

    func togglePause() {
        switch state {
        case .running, .idle:
            pause()
        case .paused:
            resume()
        case .onBreak:
            break
        }
    }

    func skipBreak() {
        guard state == .onBreak else { return }
        saveRecord()
        state = .running
        elapsedSeconds = 0
        activityMonitor.resetActivity()
        updateMenuBar()
    }

    // MARK: 内部 tick

    private func tick() {
        // 跨天重置
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let today = fmt.string(from: Date())
        if today != lastDate {
            lastDate = today
            todayActiveSeconds = 0
            todayBreakCount = 0
            elapsedSeconds = 0
            saveRecord()
        }

        if wasDNDEnabled && !settings.isDNDEnabled {
            activityMonitor.resetActivity()
        }
        wasDNDEnabled = settings.isDNDEnabled

        guard !settings.isDNDEnabled else {
            updateMenuBar()
            return
        }

        switch state {
        case .running:
            if activityMonitor.isUserIdle(timeoutSeconds: settings.idleTimeout) {
                state = .idle
                saveRecord()
            } else {
                elapsedSeconds += 1
                todayActiveSeconds += 1

                if elapsedSeconds >= settings.workDuration * 60 {
                    triggerBreak()
                }
            }

        case .idle:
            if !activityMonitor.isUserIdle(timeoutSeconds: settings.idleTimeout) {
                state = .running
            }

        case .paused, .onBreak:
            break
        }

        // 每 60 秒保存一次记录
        saveTimer += 1
        if saveTimer >= 60 {
            saveTimer = 0
            saveRecord()
        }

        updateMenuBar()
    }

    private func triggerBreak() {
        if let last = lastBreakTriggeredAt, Date().timeIntervalSince(last) < 30 {
            return
        }
        lastBreakTriggeredAt = Date()
        state = .onBreak
        todayBreakCount += 1
        saveRecord()
        onBreakTriggered?()
        updateMenuBar()
    }

    // MARK: 数据持久化

    private func saveRecord() {
        var record = DailyRecord.today()
        record.totalScreenTime = todayActiveSeconds
        record.breakCount = todayBreakCount
        // 注意：sessions 线形阶段暂不实现，保留字段供未来扩展
        DataStore.shared.saveTodayRecord(record)
    }

    // MARK: 菜单栏

    private func updateMenuBar() {
        let title: String
        switch state {
        case .running:
            title = displayTime
        case .idle:
            title = displayTime
        case .paused:
            title = displayTime
        case .onBreak:
            title = displayTime
        }
        onDisplayTimeChanged?(title)
    }
}
