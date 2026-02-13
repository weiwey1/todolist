# todolist

一个基于 **SwiftUI + SwiftData** 的任务规划应用，支持列表与日历双视图、优先级/标签/截止时间管理、本地提醒和批量操作。

## 功能特性

- 列表 / 日历视图切换
- 任务字段：标题、Markdown 描述、截止时间、优先级、标签、完成状态、重点标记
- 高级筛选：完成状态、优先级、标签、到期区间（逾期/今天/本周/无截止）
- 排序策略：未完成任务按 `截止时间 -> 优先级 -> 创建时间`，已完成任务按完成时间倒序
- 批量操作：完成/取消完成、批量加标签、批量删标签、删除
- 删除后 5 秒内撤销
- 本地通知提醒（可配置提醒偏移）
- 快捷键支持（如 `⌘F`、`⌘A`、`⌘N`、`⌘Delete`）

## 技术栈

- SwiftUI
- SwiftData (`@Model`, `@Query`, `ModelContainer`)
- UserNotifications（本地提醒）
- XCTest + Swift Testing

## 工程结构

```text
.
├── todolist/
│   ├── ContentView.swift              # 主界面与交互流程
│   ├── Item.swift                     # SwiftData 任务模型
│   ├── TaskDomain.swift               # 领域类型、筛选与排序服务
│   ├── ReminderService.swift          # 通知权限与提醒调度
│   ├── todolistApp.swift              # App 入口与容器配置
│   └── UI/
│       ├── DesignSystem.swift         # 主题与设计 Token
│       └── TaskUIComponents.swift     # 复用 UI 组件
├── todolistTests/
│   └── todolistTests.swift            # 领域逻辑单元测试
├── todolistUITests/
│   └── todolistUITests.swift          # 关键 UI 路径测试
└── PLAN.md                            # 升级规划文档
```

## 运行要求

- Xcode 17+
- iOS Simulator（推荐 iOS 26.x 运行时）

## 本地运行

1. 打开工程：`todolist.xcodeproj`
2. 选择 Scheme：`todolist`
3. 选择模拟器并运行

## 命令行构建与测试

```bash
# 构建
xcodebuild -scheme todolist -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build

# 先查看可用模拟器
xcodebuild -scheme todolist -showdestinations

# 在具体模拟器上运行测试（示例）
xcodebuild -scheme todolist -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## 数据与提醒说明

- 数据默认持久化在应用容器（SwiftData）
- 任务保存/更新时会同步重建提醒
- 若提醒时间已过去且截止时间仍在未来，会回退到截止时刻提醒

## 已覆盖测试

- 文本与标签规范化
- 筛选与排序逻辑
- 到期区间过滤
- 完成时间戳行为
- SwiftData 内存容器持久化
- UI：添加任务、筛选入口存在性、启动性能

## 未来可扩展方向

- CloudKit 同步
- 标签独立模型化（统计与治理）
- 更完整的快捷键映射与 iPad/macOS 多栏体验
- 更细的通知策略（重复提醒、到期后升级提醒）
