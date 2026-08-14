import SwiftUI

/// 数据 Tab · 今日区块 + 本月区块（大字标题，无图标，紧密间距）
struct HistoryTab: View {
    @State private var monthRecords: [DailyRecord] = []
    @State private var daysInMonth: Int = 30
    @State private var monthPrefix: String = ""

    private var todayRecord: DailyRecord {
        monthRecords.first(where: { $0.dateString == todayStr }) ?? emptyRecord(todayStr)
    }
    private var maxScreenTime: Int { max(monthRecords.map(\.totalScreenTime).max() ?? 1, 1) }
    private var maxBreakCount: Int { max(monthRecords.map(\.breakCount).max() ?? 1, 1) }
    private var monthTime: Int { monthRecords.reduce(0) { $0 + $1.totalScreenTime } }
    private var monthBreaks: Int { monthRecords.reduce(0) { $0 + $1.breakCount } }
    private var todayStr: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 今日
            Text("今日").font(.title2).fontWeight(.bold).padding(.bottom, 4)

            HStack(spacing: 8) {
                todayCard(label: "屏幕时长", value: fmtHM(todayRecord.totalScreenTime), color: .accentColor)
                todayCard(label: "休息次数", value: "\(todayRecord.breakCount)次", color: .green)
            }

            // 本月
            Text("本月").font(.title2).fontWeight(.bold).padding(.top, 14).padding(.bottom, 4)

            HStack(spacing: 8) {
                heatmapBlock(title: "屏幕时长", total: fmtHM(monthTime),
                             color: .blue, maxVal: maxScreenTime,
                             valFor: { $0.totalScreenTime })
                heatmapBlock(title: "休息次数", total: "\(monthBreaks)次",
                             color: .green, maxVal: maxBreakCount,
                             valFor: { $0.breakCount })
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .onAppear(perform: loadData)
    }

    // MARK: 今日卡片（标签在上，数字在下）

    private func todayCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.system(.title2, design: .monospaced)).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
    }

    // MARK: 热力图（大格子，紧间距）

    private func heatmapBlock(title: String, total: String, color: Color,
                              maxVal: Int, valFor: @escaping (DailyRecord) -> Int) -> some View {
        let cols = 7
        let rows = Int(ceil(Double(daysInMonth) / Double(cols)))
        let cell: CGFloat = 15

        return VStack(spacing: 4) {
            HStack(spacing: 3) {
                Text(title).font(.system(size: 10)).foregroundColor(.secondary)
                Text("·").font(.system(size: 10)).foregroundColor(.secondary)
                Text(total).font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)

            VStack(spacing: 2.5) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 2.5) {
                        ForEach(0..<cols, id: \.self) { col in
                            let day = row * cols + col + 1
                            if day <= daysInMonth {
                                let ds = "\(monthPrefix)-\(String(format: "%02d", day))"
                                let rec = monthRecords.first(where: { $0.dateString == ds })
                                let v = rec.map(valFor) ?? 0
                                let p = maxVal > 0 ? CGFloat(v)/CGFloat(maxVal) : 0
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color.opacity(0.1 + p * 0.9))
                                    .frame(width: cell, height: cell)
                                    .help("\(ds): \(v)")
                            } else { Color.clear.frame(width: cell, height: cell) }
                        }
                    }
                }
            }
            .padding(6)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(0.05)))
    }

    // MARK: 辅助

    private func loadData() {
        let cal = Calendar.current; let now = Date()
        let c = cal.dateComponents([.year, .month], from: now)
        monthPrefix = String(format: "%d-%02d", c.year!, c.month!)
        daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        monthRecords = DataStore.shared.loadAllRecords().filter { $0.dateString.hasPrefix(monthPrefix) }
        if !monthRecords.contains(where: { $0.dateString == todayStr }) {
            monthRecords.append(emptyRecord(todayStr))
        }
    }
    private func emptyRecord(_ d: String) -> DailyRecord {
        DailyRecord(dateString: d, totalScreenTime: 0, breakCount: 0, sessions: [])
    }
    private func fmtHM(_ s: Int) -> String {
        let h = s/3600, m = (s%3600)/60
        return h>0 ? "\(h)h\(m)m" : "\(m)m"
    }
}
