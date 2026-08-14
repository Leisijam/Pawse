import Foundation

/// 每日使用记录
struct DailyRecord: Codable, Identifiable {
    var id: String { dateString }
    /// 日期字符串 "yyyy-MM-dd"
    let dateString: String
    /// 总屏幕时长（秒）
    var totalScreenTime: Int
    /// 休息次数
    var breakCount: Int
    /// 工作时段列表
    var sessions: [Session]

    struct Session: Codable {
        let startTime: Date
        let endTime: Date
        var duration: Int {
            Int(endTime.timeIntervalSince(startTime))
        }
    }

    /// 今日记录
    static func today() -> DailyRecord {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return DailyRecord(
            dateString: formatter.string(from: Date()),
            totalScreenTime: 0,
            breakCount: 0,
            sessions: []
        )
    }

    /// 格式化总时长 "X 小时 Y 分钟"
    var formattedDuration: String {
        let hours = totalScreenTime / 3600
        let minutes = (totalScreenTime % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        }
        return "\(minutes) 分钟"
    }
}
