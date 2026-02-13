# ToDoList 进阶版升级方案（规划优先 + 强功能 + 一次性交付）

## Summary
在现有基础上一次性升级为“任务规划型”ToDo：以 `列表 + 日历切换` 为核心，补齐 `截止时间/优先级/标签/高级筛选/本地提醒/批量操作/快捷键`，并继续保持当前现代卡片风格和 iPhone+iPad+mac 统一体验。  
数据层继续使用 SwiftData（本地存储），但结构按后续同步可扩展设计。

## Public Interfaces / Types Changes

1. `Item` 模型扩展（SwiftData）
- 新增字段：
  - `dueAt: Date?`
  - `priority: TaskPriority`（`low/medium/high/urgent`）
  - `tags: [String]`（或单独 `Tag` 模型 + 关系，推荐后者）
  - `isFlagged: Bool`
  - `completedAt` 保留并参与统计
- 保持已有：
  - `title`
  - `markdownDescription`
  - `isCompleted`
  - `createdAt/updatedAt`

2. 新增类型
- `enum TaskPriority: Int, CaseIterable, Codable, Identifiable`
- `enum TaskSortMode`（固定策略：截止时间优先）
- `struct TaskFilterState`（标签、优先级、到期区间、完成状态）
- `enum CalendarScope`（`week/month`）
- `struct ReminderConfig`（提醒时间偏移、是否启用）

3. 新增服务层接口
- `TaskQueryService`: 统一组合筛选/排序逻辑
- `ReminderService`: 本地通知申请、调度、取消、重建
- `ShortcutAction`: mac/iPad 键盘命令映射（新建、完成、删除、批量标记）

## Feature & UX Implementation

1. 信息架构升级
- 顶部导航新增主视图切换：`列表` / `日历`
- 列表页保留卡片样式，新增“高级筛选抽屉”（标签、优先级、到期）
- 日历页显示周/月网格与任务点位，点击日期联动当天任务列表

2. 任务核心能力
- 新建/编辑页增加：
  - 截止日期选择器（含“今天/明天/本周末”快捷）
  - 优先级选择器（颜色语义）
  - 标签编辑器（多标签）
  - Markdown 描述继续支持输入与预览
- 排序规则固定为：
  - 未完成：`dueAt asc(nil last) -> priority desc -> createdAt desc`
  - 已完成：保持置底并按 `completedAt desc`

3. 高效交互（重点）
- 列表支持多选模式（iPad/mac 优先优化）
- 批量操作：`完成/取消完成/加标签/删标签/删除`
- 快捷键（mac 与外接键盘 iPad）：
  - `⌘N` 新建任务
  - `⌘F` 聚焦筛选
  - `⌘↩` 完成切换
  - `⌘⌫` 删除
  - `⌘A` 全选（在多选上下文）

4. 提醒与到期体验
- 接入本地通知（UserNotifications）
- 在任务保存/更新时重建对应提醒
- 到期视觉增强：
  - 逾期：红色语义 + “已逾期”
  - 今日到期：强调色高亮
  - 未来：普通次级信息

5. 界面与交互细化
- 保持青绿主题，增强优先级颜色体系（不替代主色，仅语义补充）
- 日历与列表切换使用轻动效（0.22-0.28s）
- 筛选抽屉、批量工具栏、通知授权提示统一卡片语言
- iPad/mac 宽屏下：
  - 左侧任务列表 + 右侧详情/编辑（Split-like）
  - 保持当前宽度约束策略，避免超宽阅读负担

## Data & Migration Strategy
- 版本化迁移：
  - 为新增字段提供默认值（`priority = .medium`、`isFlagged = false`）
  - `dueAt/tags` 默认空
- 如果历史库迁移失败：
  - 复用现有“容器失败 fallback”，但优先尝试迁移而非清库
- 提醒数据不单独持久化，依据 `Item` 字段可重建，避免双写不一致

## Testing & Acceptance Scenarios

1. 单元测试
- 筛选组合正确性（标签 + 优先级 + 到期区间）
- 排序稳定性（截止时间优先）
- 逾期/今日/未来状态判定
- Markdown 描述与摘要提取
- 批量操作对多任务状态一致性

2. 集成/服务测试
- `ReminderService`：创建、更新、删除任务时通知调度正确
- 通知权限拒绝时不崩溃且有 UI fallback 提示

3. UI 测试
- 新建任务并设置截止时间/优先级/标签
- 列表与日历切换
- 高级筛选生效
- 多选批量完成与删除
- mac/iPad 快捷键路径（可通过命令触发验证）

4. 跨端验收
- iPhone：单栏流畅、输入效率高
- iPad：宽屏双区可读性与操作连续性
- mac：快捷键、批量、滚动与窗口缩放行为正确

## Assumptions & Defaults
1. 本轮一次性交付，不拆阶段。  
2. 数据策略为“本地 SwiftData + 可扩展同步架构”，本轮不接 CloudKit。  
3. 提醒使用本地通知，不做远程推送。  
4. 标签先用轻量字符串集合实现；若后续需要统计/治理再升级为独立 `Tag` 模型。  
5. 继续沿用现有视觉语言（现代卡片 + 青绿主色），避免推倒重做导致学习成本上升。
