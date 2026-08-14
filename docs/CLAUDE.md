# CLAUDE.md — Pawse 项目助手指引

## 项目概述

Pawse 是一款 macOS 菜单栏应用，帮助用户管理屏幕使用时长，超时后用全屏猫咪动画提醒休息。

- **技术**：SwiftUI + AppKit（Swift Package Manager 构建）
- **目标系统**：macOS 14.0+
- **工作目录**：`/Users/zhaozhan/Desktop/MyFirstApp`

---

## 标准文件索引

| 文件 | 路径 | 说明 |
|------|------|------|
| 产品需求文档（当前状态权威说明） | [docs/PRD.md](docs/PRD.md) | 基于实际代码整理，最新最准确 |
| 需求文档（立项初稿） | [docs/需求文档.md](docs/需求文档.md) | 历史文档，部分内容已被后续开发调整 |
| 技术方案（立项初稿） | [docs/技术方案.md](docs/技术方案.md) | 历史文档 |
| 设计规范（立项初稿） | [docs/设计规范.md](docs/设计规范.md) | 历史文档 |
| 开发计划（立项初稿） | [docs/开发计划.md](docs/开发计划.md) | 历史文档，5 个阶段均已完成 |
| 开发日志 | [开发日志.md](开发日志.md) | 按时间顺序记录的开发过程 |

开始任何开发工作前，先阅读 [docs/PRD.md](docs/PRD.md) 了解项目当前实际状态；早期规划文档仅作历史参考。

---

## 工作原则

> 项目 5 个开发阶段已于 2026-07-12 全部完成，当前处于「已上线迭代」阶段；以下「分阶段执行」原则已不适用于新需求，保留作历史参考。

### 1. 分阶段执行（历史阶段，已完成）
最初按 [开发计划](docs/开发计划.md) 中的 5 个阶段推进，目前均已完成并持续迭代中。

### 2. 操作前确认
每一步操作（包括写文件、运行命令、修改代码）前，先向用户说明要做什么，用户确认后再执行。**不要自主决定并执行。**

### 3. 稳定优先
- 每次改动后用 `swift build` 确认编译无错误、无警告
- 不使用未经验证的第三方库（当前项目零外部依赖）
- 代码写清楚注释，只在必要处说明"为什么"，不写"是什么"

### 4. 开发日志
每次完成一批改动后，更新 [开发日志.md](开发日志.md)，记录：
- 日期
- 已完成事项
- 待办事项 / 已知问题

---

## 项目结构

```
MyFirstApp/
├── docs/
│   ├── PRD.md              ← 当前状态权威文档，优先阅读
│   ├── 需求文档.md           ← 历史文档
│   ├── 技术方案.md           ← 历史文档
│   ├── 设计规范.md           ← 历史文档
│   └── 开发计划.md           ← 历史文档
├── Pawse/                   ← Swift Package（swift build / swift run）
│   ├── Package.swift
│   ├── Sources/
│   │   ├── App.swift
│   │   ├── Managers/
│   │   │   ├── TimerManager.swift
│   │   │   ├── ActivityMonitor.swift
│   │   │   ├── BreakWindowManager.swift
│   │   │   └── DataStore.swift
│   │   ├── Models/
│   │   │   ├── AppSettings.swift
│   │   │   └── DailyRecord.swift
│   │   ├── Views/
│   │   │   ├── MenuBarView.swift
│   │   │   ├── TimerTab.swift
│   │   │   ├── HistoryTab.swift
│   │   │   ├── SettingsTab.swift
│   │   │   └── BreakOverlayView.swift
│   │   └── Resources/
│   │       └── DefaultCat.mp4   ← 内置默认休息动画视频
│   └── Pawse.xcodeproj      ← 备用 Xcode 工程（日常以 swift build/run 为准）
├── 猫咪素材/                 ← 设计稿/素材原始文件，非构建产物
├── 开发日志.md
└── CLAUDE.md
```

---

## 用户偏好

- 用户是编程初学者，代码注释要清晰
- 设计风格：黑白灰简洁风，贴近 macOS 原生
- 应用名：**Pawse**（原开发代号 PawBreak，已正式更名）
- 日常开发用 `swift build` / `swift run` 而非 Xcode 直接构建；`Pawse.xcodeproj` 为备用
