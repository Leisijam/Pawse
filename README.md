# Pawse

一款 macOS 菜单栏应用,帮助长时间使用电脑的人养成规律休息的习惯。应用在后台监测键盘/鼠标活动来计算专注使用时长,达到设定时长后会用一段全屏猫咪动画提醒你休息,并记录每日使用与休息数据。

## 下载安装

1. 前往 [Releases](../../releases) 页面,下载最新版本的 `Pawse-vX.X.X-macOS.zip`
2. 解压后把 `Pawse.app` 拖到「应用程序」文件夹
3. **首次打开会被 macOS 拦截**(因为这是个人开发者未签名的 App),按下面的方法之一绕过:
   - **方法一(推荐)**:在「访达」里找到 `Pawse.app`,**按住 Control 点击(或右键)→ 打开**,弹窗里再点一次「打开」
   - **方法二**:打开终端,执行:
     ```bash
     xattr -cr /Applications/Pawse.app
     ```
4. 打开后 App 会出现在屏幕右上角菜单栏(没有 Dock 图标,是正常现象)

## 系统要求

- macOS 14.0 或更高版本

## 功能

- 后台自动计时,专注时长达标后全屏猫咪动画提醒休息
- 一键「免打扰」暂停提醒
- 「数据」Tab 展示今日 / 本月使用与休息时长
- 基于系统级事件综合判断键盘、鼠标移动/点击/滚动,避免鼠标在动但没操作被误判为专注

更详细的产品说明见 [docs/PRD.md](docs/PRD.md)。

## 本地开发

技术栈:SwiftUI + AppKit,Swift Package Manager 构建,零外部依赖。

```bash
cd Pawse
swift build      # 编译
swift run        # 编译并运行
```

也可以用 `Pawse/Pawse.xcodeproj` 在 Xcode 里打开(备用工程,以 `swift build`/`swift run` 为准)。

## License

[MIT](LICENSE)
