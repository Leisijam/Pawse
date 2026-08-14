import SwiftUI

struct MenuBarView: View {
    @State private var selectedTab: TabItem = .timer
    let timerManager: TimerManager

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab)
            Divider()
            contentArea
                .frame(width: 299, height: 372)
                .padding(14)
        }
        .frame(width: 400, height: 400)
    }

    @ViewBuilder
    private var contentArea: some View {
        switch selectedTab {
        case .timer:    TimerTab(timerManager: timerManager)
        case .history:  HistoryTab()
        case .settings: SettingsTab(settings: timerManager.settings)
        }
    }
}

enum TabItem: String, CaseIterable {
    case timer = "计时", history = "数据", settings = "设置"
    var icon: String {
        switch self {
        case .timer: "timer"; case .history: "calendar"; case .settings: "gearshape"
        }
    }
}

// MARK: - 侧边栏

struct SidebarView: View {
    @Binding var selectedTab: TabItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            avatarImage.padding(.top, 16).padding(.bottom, 14)

            VStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    SidebarTabButton(tab: tab, isSelected: selectedTab == tab) { selectedTab = tab }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 72)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func bundledImage(named name: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }

    @ViewBuilder
    private var avatarImage: some View {
        let dayImg = bundledImage(named: "tab_day")
        let nightImg = bundledImage(named: "tab_night")
        let img = colorScheme == .dark ? (nightImg ?? dayImg) : (dayImg ?? nightImg)
        if let img = img {
            Image(nsImage: img).resizable().aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44).clipShape(Circle())
        } else {
            Image(systemName: "cat.fill")
                .font(.system(size: 26))
                .foregroundColor(colorScheme == .dark ? .white : .gray)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        }
    }
}

// MARK: - 侧边栏按钮

struct SidebarTabButton: View {
    let tab: TabItem; let isSelected: Bool; let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon).font(.system(size: 22))
            Text(tab.rawValue).font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(isSelected ? .accentColor
                         : (colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.accentColor.opacity(0.12) : .clear))
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .padding(.horizontal, 6)
    }
}
