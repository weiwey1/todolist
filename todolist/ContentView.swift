//
//  ContentView.swift
//  todolist
//
//  Created by 梁庆卫 on 2026/2/13.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: [SortDescriptor(\Item.createdAt, order: .reverse)]) private var items: [Item]

    @State private var inputText = ""
    @State private var viewMode: MainViewMode = .list
    @State private var filterState = TaskFilterState()
    @State private var showAdvancedFilter = false
    @State private var filterDraftTagText = ""

    @State private var calendarScope: CalendarScope = .month
    @State private var selectedDate = Date()
    @State private var clockNow = Date()
    @State private var lastDayAnchor = Date()

    @State private var isSelectionMode = false
    @State private var selectedTaskIDs: Set<UUID> = []
    @State private var batchTagText = ""
    @State private var batchTagAction: BatchTagAction?

    @State private var pendingUndoSnapshot: DeletedTaskSnapshot?
    @State private var undoDismissTask: Task<Void, Never>?
    private let reminderService = ReminderService()

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    private var sections: (active: [Item], completed: [Item]) {
        TaskQueryService.split(items: items, filter: filterState)
    }

    private var selectedItems: [Item] {
        items.filter { selectedTaskIDs.contains($0.id) }
    }

    private var selectedDateItems: [Item] {
        (sections.active + sections.completed)
            .filter { item in
                guard let dueAt = item.dueAt else { return false }
                return Calendar.current.isDate(dueAt, inSameDayAs: selectedDate)
            }
            .sorted { lhs, rhs in
                (lhs.dueAt ?? .distantFuture) < (rhs.dueAt ?? .distantFuture)
            }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let metrics = LayoutMetrics(width: proxy.size.width)
                ZStack {
                    backgroundLayer

                    Group {
                        switch viewMode {
                        case .list:
                            taskList(metrics: metrics)
                        case .calendar:
                            calendarBoard(metrics: metrics)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                .safeAreaInset(edge: .top, spacing: theme.spacing.md) {
                    topPanel(metrics: metrics)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: theme.spacing.sm) {
                        if isSelectionMode && !selectedTaskIDs.isEmpty {
                            BatchActionBar(
                                selectedCount: selectedTaskIDs.count,
                                onComplete: { applyBatchCompletion(true) },
                                onUncomplete: { applyBatchCompletion(false) },
                                onDelete: deleteSelected,
                                onAddTag: { batchTagAction = .add },
                                onRemoveTag: { batchTagAction = .remove },
                                theme: theme
                            )
                        }

                        if pendingUndoSnapshot != nil {
                            UndoFloatingBar(onUndo: undoDelete, theme: theme)
                        }
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.bottom, theme.spacing.sm)
                    .frame(maxWidth: metrics.contentWidth)
                }
                .animation(.easeInOut(duration: 0.25), value: showAdvancedFilter)
                .animation(.easeInOut(duration: 0.25), value: viewMode)
                .animation(.easeInOut(duration: 0.25), value: selectedTaskIDs.count)
                .animation(.easeInOut(duration: 0.25), value: pendingUndoSnapshot != nil)
            }
            .navigationTitle("任务规划")
#if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(isSelectionMode ? "完成选择" : "多选") {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedTaskIDs.removeAll()
                        }
                    }

                    Button("筛选") {
                        showAdvancedFilter.toggle()
                    }
                    .keyboardShortcut("f", modifiers: [.command])

                    if isSelectionMode {
                        Button("全选", action: selectAllVisible)
                            .keyboardShortcut("a", modifiers: [.command])
                    }
                }
            }
            .alert(
                batchTagAction == nil ? "" : (batchTagAction == .add ? "批量加标签" : "批量删标签"),
                isPresented: Binding(
                    get: { batchTagAction != nil },
                    set: { value in
                        if !value { batchTagAction = nil }
                    }
                )
            ) {
                TextField("标签（支持逗号分隔）", text: $batchTagText)
                Button("取消", role: .cancel) {
                    batchTagText = ""
                }
                Button("应用", action: applyBatchTagAction)
            } message: {
                Text("将对选中的任务统一处理标签")
            }
            .task {
                await reminderService.requestAuthorizationIfNeeded()
                await reminderService.rebuild(for: items)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    if Task.isCancelled { return }
                    await MainActor.run {
                        clockNow = Date()
                    }
                }
            }
            .onChange(of: clockNow) { newValue in
                syncSelectedDateIfNeeded(with: newValue)
            }
        }
    }

    private func taskList(metrics: LayoutMetrics) -> some View {
        List {
            if !sections.active.isEmpty {
                Section {
                    ForEach(sections.active) { item in
                        TaskCardRow(
                            item: item,
                            destination: TaskEditorView(item: item, onSave: scheduleReminder),
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedTaskIDs.contains(item.id),
                            onSelectToggle: { toggleSelection(for: item) },
                            onToggle: { toggleCompletion(for: item) },
                            onDelete: { delete(item) },
                            theme: theme
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.vertical, theme.spacing.xs)
                    }
                } header: {
                    sectionHeader("未完成", metrics: metrics)
                }
            }

            if !sections.completed.isEmpty {
                Section {
                    ForEach(sections.completed) { item in
                        TaskCardRow(
                            item: item,
                            destination: TaskEditorView(item: item, onSave: scheduleReminder),
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedTaskIDs.contains(item.id),
                            onSelectToggle: { toggleSelection(for: item) },
                            onToggle: { toggleCompletion(for: item) },
                            onDelete: { delete(item) },
                            theme: theme
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.vertical, theme.spacing.xs)
                    }
                } header: {
                    sectionHeader("已完成", metrics: metrics)
                }
            }

            if sections.active.isEmpty && sections.completed.isEmpty {
                EmptyStateCard(theme: theme)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.vertical, theme.spacing.lg)
                    .frame(maxWidth: metrics.contentWidth)
            }
        }
        .frame(maxWidth: metrics.contentWidth)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func calendarBoard(metrics: LayoutMetrics) -> some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                EditorCardSection(title: "日历范围", theme: theme) {
                    Picker("范围", selection: $calendarScope) {
                        ForEach(CalendarScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(theme.colors.accent)
                }

                if calendarScope == .month {
                    EditorCardSection(title: "选择日期", theme: theme) {
                        DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    }
                } else {
                    weekStrip
                }

                EditorCardSection(
                    title: "\(selectedDate.formatted(date: .abbreviated, time: .omitted)) 的任务",
                    theme: theme
                ) {
                    if selectedDateItems.isEmpty {
                        Text("当天没有任务")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    } else {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            ForEach(selectedDateItems) { item in
                                HStack(spacing: theme.spacing.sm) {
                                    PriorityBadge(priority: item.priority, theme: theme)
                                    Text(item.title)
                                        .font(theme.typography.body)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .lineLimit(2)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.bottom, 100)
            .frame(maxWidth: metrics.contentWidth)
            .frame(maxWidth: .infinity)
        }
    }

    private var weekStrip: some View {
        let dates = weekDates(containing: selectedDate)
        return EditorCardSection(title: "本周", theme: theme) {
            HStack(spacing: theme.spacing.sm) {
                ForEach(dates, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 4) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                            Text(date.formatted(.dateTime.day()))
                        }
                        .font(theme.typography.caption)
                        .foregroundStyle(
                            Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : theme.colors.textPrimary
                        )
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                .fill(
                                    Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                    ? theme.colors.accent
                                    : theme.colors.mutedSurface
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func topPanel(metrics: LayoutMetrics) -> some View {
        VStack(spacing: theme.spacing.md) {
            if metrics.isWide {
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    TaskInputCard(
                        text: $inputText,
                        onAdd: addTask,
                        canAdd: TaskDomain.normalizedTitle(inputText) != nil,
                        theme: theme
                    )
                    .frame(maxWidth: .infinity)

                    MainModeCard(
                        mode: $viewMode,
                        completionScope: $filterState.completion,
                        theme: theme
                    )
                    .frame(width: 320)
                }
            } else {
                TaskInputCard(
                    text: $inputText,
                    onAdd: addTask,
                    canAdd: TaskDomain.normalizedTitle(inputText) != nil,
                    theme: theme
                )

                MainModeCard(
                    mode: $viewMode,
                    completionScope: $filterState.completion,
                    theme: theme
                )
            }

            if showAdvancedFilter {
                AdvancedFilterCard(
                    filterState: $filterState,
                    draftTagText: $filterDraftTagText,
                    onAddTag: addFilterTags,
                    onRemoveTag: removeFilterTag,
                    onClear: clearFilters,
                    theme: theme
                )
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .frame(maxWidth: metrics.contentWidth)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [theme.colors.gradientTop, theme.colors.gradientBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.colors.accent.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 44)
                .offset(x: 90, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(theme.colors.accent.opacity(0.1))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: -80, y: 130)
        }
        .ignoresSafeArea()
    }

    private func sectionHeader(_ title: String, metrics: LayoutMetrics) -> some View {
        HStack {
            Text(title)
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, theme.spacing.md)
        .textCase(nil)
    }

    private func addTask() {
        guard let normalized = TaskDomain.normalizedTitle(inputText) else { return }
        let item = Item(title: normalized)
        withAnimation(.easeInOut(duration: 0.24)) {
            modelContext.insert(item)
            inputText = ""
        }
        scheduleReminder(item)
    }

    private func toggleCompletion(for item: Item) {
        withAnimation(.easeInOut(duration: 0.24)) {
            item.isCompleted.toggle()
            item.updatedAt = .now
            item.completedAt = item.isCompleted ? .now : nil
        }
    }

    private func toggleSelection(for item: Item) {
        if selectedTaskIDs.contains(item.id) {
            selectedTaskIDs.remove(item.id)
        } else {
            selectedTaskIDs.insert(item.id)
        }
    }

    private func selectAllVisible() {
        let visibleIDs = Set((sections.active + sections.completed).map(\.id))
        selectedTaskIDs = visibleIDs
    }

    private func delete(_ item: Item) {
        let snapshot = DeletedTaskSnapshot(item: item)
        withAnimation(.easeInOut(duration: 0.24)) {
            modelContext.delete(item)
        }
        selectedTaskIDs.remove(item.id)
        pendingUndoSnapshot = snapshot
        scheduleUndoDismiss()
        Task { await reminderService.cancel(for: item.id) }
    }

    private func deleteSelected() {
        for item in selectedItems {
            delete(item)
        }
        selectedTaskIDs.removeAll()
    }

    private func undoDelete() {
        guard let snapshot = pendingUndoSnapshot else { return }
        withAnimation(.easeInOut(duration: 0.24)) {
            restore(snapshot)
        }
        pendingUndoSnapshot = nil
        undoDismissTask?.cancel()
    }

    private func restore(_ snapshot: DeletedTaskSnapshot) {
        let item = snapshot.makeItem()
        modelContext.insert(item)
        scheduleReminder(item)
    }

    private func scheduleUndoDismiss() {
        undoDismissTask?.cancel()
        undoDismissTask = Task {
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled { return }
            await MainActor.run {
                pendingUndoSnapshot = nil
            }
        }
    }

    private func scheduleReminder(_ item: Item) {
        Task {
            await reminderService.schedule(for: item)
        }
    }

    private func applyBatchCompletion(_ completed: Bool) {
        withAnimation(.easeInOut(duration: 0.24)) {
            for item in selectedItems {
                item.isCompleted = completed
                item.updatedAt = .now
                item.completedAt = completed ? .now : nil
            }
        }
    }

    private func applyBatchTagAction() {
        guard let action = batchTagAction else { return }
        let tags = Set(TaskDomain.normalizedTags(batchTagText))
        guard !tags.isEmpty else {
            batchTagText = ""
            batchTagAction = nil
            return
        }

        for item in selectedItems {
            let current = Set(item.tags.map { $0.lowercased() })
            switch action {
            case .add:
                let normalizedTags = Set(tags.map { $0.lowercased() })
                let merged = current.union(normalizedTags)
                item.tags = merged.sorted()
            case .remove:
                let normalizedTags = Set(tags.map { $0.lowercased() })
                let remained = current.subtracting(normalizedTags)
                item.tags = remained.sorted()
            }
            item.updatedAt = .now
            scheduleReminder(item)
        }

        batchTagText = ""
        batchTagAction = nil
    }

    private func addFilterTags() {
        let tags = TaskDomain.normalizedTags(filterDraftTagText)
        for tag in tags {
            filterState.requiredTags.insert(tag.lowercased())
        }
        filterDraftTagText = ""
    }

    private func removeFilterTag(_ tag: String) {
        filterState.requiredTags.remove(tag.lowercased())
    }

    private func clearFilters() {
        filterState = TaskFilterState(completion: filterState.completion)
        filterDraftTagText = ""
    }

    private func weekDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [date] }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    private func syncSelectedDateIfNeeded(with newValue: Date) {
        let calendar = Calendar.current
        guard !calendar.isDate(lastDayAnchor, inSameDayAs: newValue) else { return }
        if calendar.isDate(selectedDate, inSameDayAs: lastDayAnchor) {
            selectedDate = newValue
        }
        lastDayAnchor = newValue
    }
}

private struct LayoutMetrics {
    let isWide: Bool
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat

    init(width: CGFloat) {
        if width >= 900 {
            isWide = true
            contentWidth = 980
            horizontalPadding = 24
        } else if width >= 700 {
            isWide = true
            contentWidth = 860
            horizontalPadding = 22
        } else {
            isWide = false
            contentWidth = nil
            horizontalPadding = 18
        }
    }
}

private struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let item: Item
    let onSave: (Item) -> Void
    @State private var draftTitle: String
    @State private var draftDescription: String
    @State private var draftDueAt: Date
    @State private var hasDueAt: Bool
    @State private var draftPriority: TaskPriority
    @State private var draftTagsText: String
    @State private var reminderEnabled: Bool
    @State private var reminderOffsetMinutes: Int
    @State private var isFlagged: Bool

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    init(item: Item, onSave: @escaping (Item) -> Void) {
        self.item = item
        self.onSave = onSave
        _draftTitle = State(initialValue: item.title)
        _draftDescription = State(initialValue: item.markdownDescription)
        _draftDueAt = State(initialValue: item.dueAt ?? .now)
        _hasDueAt = State(initialValue: item.dueAt != nil)
        _draftPriority = State(initialValue: item.priority)
        _draftTagsText = State(initialValue: item.tags.joined(separator: ", "))
        _reminderEnabled = State(initialValue: item.reminderEnabled)
        _reminderOffsetMinutes = State(initialValue: item.reminderOffsetMinutes)
        _isFlagged = State(initialValue: item.isFlagged)
    }

    var body: some View {
        GeometryReader { proxy in
            let maxWidth = proxy.size.width >= 700 ? 720.0 : .infinity

            ZStack {
                LinearGradient(
                    colors: [theme.colors.gradientTop, theme.colors.gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        EditorCardSection(title: "任务标题", theme: theme) {
                            TextField("输入任务标题", text: $draftTitle)
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                        .fill(theme.colors.mutedSurface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                        .stroke(
                                            TaskDomain.normalizedTitle(draftTitle) == nil ? theme.colors.danger : theme.colors.border,
                                            lineWidth: 1
                                        )
                                )
                                .accessibilityIdentifier("taskEditorTitleField")
                        }

                        EditorCardSection(title: "截止与优先级", theme: theme) {
                            Toggle("设置截止时间", isOn: $hasDueAt)

                            if hasDueAt {
                                DatePicker("截止时间", selection: $draftDueAt)
                                HStack(spacing: theme.spacing.sm) {
                                    Button("今天") {
                                        draftDueAt = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
                                    }
                                    .buttonStyle(.bordered)
                                    Button("明天") {
                                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                                        draftDueAt = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: tomorrow) ?? tomorrow
                                    }
                                    .buttonStyle(.bordered)
                                    Button("本周末") {
                                        draftDueAt = weekendDate()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            Picker("优先级", selection: $draftPriority) {
                                ForEach(TaskPriority.allCases) { level in
                                    Text(level.title).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)

                            Toggle("标记重点", isOn: $isFlagged)
                        }

                        EditorCardSection(title: "标签与提醒", theme: theme) {
                            TextField("标签（逗号分隔）", text: $draftTagsText)
                                .textFieldStyle(.roundedBorder)

                            Toggle("启用提醒", isOn: $reminderEnabled)
                            if reminderEnabled {
                                Picker("提醒时间", selection: $reminderOffsetMinutes) {
                                    Text("10 分钟前").tag(10)
                                    Text("30 分钟前").tag(30)
                                    Text("1 小时前").tag(60)
                                    Text("1 天前").tag(24 * 60)
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        EditorCardSection(title: "描述（Markdown）", theme: theme) {
                            TextEditor(text: $draftDescription)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(theme.colors.textPrimary)
                                .frame(minHeight: 150)
                                .padding(theme.spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                        .fill(theme.colors.mutedSurface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                        .stroke(theme.colors.border, lineWidth: 1)
                                )
                                .accessibilityIdentifier("taskEditorDescriptionField")
                        }

                        if let markdownPreview = try? AttributedString(
                            markdown: TaskDomain.normalizedMarkdownDescription(draftDescription)
                        ),
                        !TaskDomain.normalizedMarkdownDescription(draftDescription).isEmpty {
                            EditorCardSection(title: "预览", theme: theme) {
                                Text(markdownPreview)
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Button(action: save) {
                            Text("保存")
                                .font(theme.typography.section)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, theme.spacing.md)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                                .fill(TaskDomain.normalizedTitle(draftTitle) == nil ? theme.colors.textSecondary.opacity(0.35) : theme.colors.accent)
                        )
                        .disabled(TaskDomain.normalizedTitle(draftTitle) == nil)
                        .accessibilityIdentifier("taskEditorSaveButton")
                        .keyboardShortcut("s", modifiers: [.command])
                    }
                    .padding(theme.spacing.lg)
                    .frame(maxWidth: maxWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("编辑任务")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func save() {
        guard let normalized = TaskDomain.normalizedTitle(draftTitle) else { return }
        item.title = normalized
        item.markdownDescription = TaskDomain.normalizedMarkdownDescription(draftDescription)
        item.dueAt = hasDueAt ? draftDueAt : nil
        item.priority = draftPriority
        item.tags = TaskDomain.normalizedTags(draftTagsText)
        item.reminderEnabled = reminderEnabled
        item.reminderOffsetMinutes = reminderOffsetMinutes
        item.isFlagged = isFlagged
        item.updatedAt = .now
        onSave(item)
        dismiss()
    }

    private func weekendDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday, to: now) ?? now
        return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: saturday) ?? saturday
    }
}

private struct DeletedTaskSnapshot {
    let id: UUID
    let title: String
    let markdownDescription: String
    let isCompleted: Bool
    let dueAt: Date?
    let priority: TaskPriority
    let tags: [String]
    let isFlagged: Bool
    let reminderEnabled: Bool
    let reminderOffsetMinutes: Int
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?

    init(item: Item) {
        id = item.id
        title = item.title
        markdownDescription = item.markdownDescription
        isCompleted = item.isCompleted
        dueAt = item.dueAt
        priority = item.priority
        tags = item.tags
        isFlagged = item.isFlagged
        reminderEnabled = item.reminderEnabled
        reminderOffsetMinutes = item.reminderOffsetMinutes
        createdAt = item.createdAt
        updatedAt = item.updatedAt
        completedAt = item.completedAt
    }

    func makeItem() -> Item {
        Item(
            id: id,
            title: title,
            markdownDescription: markdownDescription,
            isCompleted: isCompleted,
            dueAt: dueAt,
            priority: priority,
            tags: tags,
            isFlagged: isFlagged,
            reminderEnabled: reminderEnabled,
            reminderOffsetMinutes: reminderOffsetMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt
        )
    }
}

private enum BatchTagAction: Equatable {
    case add
    case remove
}

#Preview("Main - Light") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("Main - Dark") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .preferredColorScheme(.dark)
}
