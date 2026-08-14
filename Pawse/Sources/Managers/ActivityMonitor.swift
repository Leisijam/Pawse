import Cocoa

/// 系统级空闲检测器
/// 通过 CGEventSource 查询系统最后一次输入时间，无需权限，100% 可靠
final class ActivityMonitor {

    // MARK: 启动 / 停止

    func start() {
        // CGEventSource 方式不需要启动，查询时直接读系统状态
    }

    func stop() {}

    /// 重置（手动恢复时调用）
    func resetActivity() {
        // 不需要重置——系统自动记录最新输入
    }

    /// 检查用户是否空闲
    func isUserIdle(timeoutSeconds: Int) -> Bool {
        let idle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .mouseMoved)
        // 也检查键盘和点击
        let keyIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .keyDown)
        let clickIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .leftMouseDown)
        let scrollIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState, eventType: .scrollWheel)

        let shortest = min(idle, keyIdle, clickIdle, scrollIdle)
        return shortest > Double(timeoutSeconds)
    }
}
