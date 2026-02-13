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
    @State private var selectedFilter: TaskFilter = .all
    @State private var pendingUndoSnapshot: DeletedTaskSnapshot?
    @State private var undoDismissTask: Task<Void, Never>?

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    private var sections: (active: [Item], completed: [Item]) {
        TaskDomain.split(items: items, filter: selectedFilter)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let metrics = LayoutMetrics(width: proxy.size.width)
                ZStack {
                    backgroundLayer

                    taskList(metrics: metrics)
                }
                .safeAreaInset(edge: .top, spacing: theme.spacing.md) {
                    topPanel(metrics: metrics)
                }
                .safeAreaInset(edge: .bottom) {
                    if pendingUndoSnapshot != nil {
                        UndoFloatingBar(onUndo: undoDelete, theme: theme)
                            .padding(.horizontal, metrics.horizontalPadding)
                            .padding(.bottom, theme.spacing.sm)
                            .frame(maxWidth: metrics.contentWidth)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.24), value: pendingUndoSnapshot != nil)
            }
            .navigationTitle("任务清单")
#if os(iOS)
            .toolbarBackground(.hidden, for: .navigationBar)
#endif
        }
    }

    private func taskList(metrics: LayoutMetrics) -> some View {
        List {
            if !sections.active.isEmpty {
                Section {
                    ForEach(sections.active) { item in
                        TaskCardRow(
                            item: item,
                            destination: TaskEditorView(item: item),
                            onToggle: { toggleCompletion(for: item) },
                            onDelete: { delete(item) },
                            theme: theme
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.vertical, theme.spacing.xs)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
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
                            destination: TaskEditorView(item: item),
                            onToggle: { toggleCompletion(for: item) },
                            onDelete: { delete(item) },
                            theme: theme
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.vertical, theme.spacing.xs)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
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
        .animation(.easeInOut(duration: 0.24), value: selectedFilter)
        .animation(.easeInOut(duration: 0.24), value: sections.active.count + sections.completed.count)
    }

    private func topPanel(metrics: LayoutMetrics) -> some View {
        Group {
            if metrics.isWide {
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    TaskInputCard(
                        text: $inputText,
                        onAdd: addTask,
                        canAdd: TaskDomain.normalizedTitle(inputText) != nil,
                        theme: theme
                    )
                    .frame(maxWidth: .infinity)

                    FilterSegmentCard(
                        selectedFilter: $selectedFilter,
                        theme: theme
                    )
                    .frame(width: 280)
                }
            } else {
                VStack(spacing: theme.spacing.md) {
                    TaskInputCard(
                        text: $inputText,
                        onAdd: addTask,
                        canAdd: TaskDomain.normalizedTitle(inputText) != nil,
                        theme: theme
                    )

                    FilterSegmentCard(
                        selectedFilter: $selectedFilter,
                        theme: theme
                    )
                }
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
    }

    private func toggleCompletion(for item: Item) {
        withAnimation(.easeInOut(duration: 0.24)) {
            item.isCompleted.toggle()
            item.updatedAt = .now
            item.completedAt = item.isCompleted ? .now : nil
        }
    }

    private func delete(_ item: Item) {
        let snapshot = DeletedTaskSnapshot(item: item)
        withAnimation(.easeInOut(duration: 0.24)) {
            modelContext.delete(item)
        }
        pendingUndoSnapshot = snapshot
        scheduleUndoDismiss()
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
        modelContext.insert(snapshot.makeItem())
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
    @State private var draftTitle: String
    @State private var draftDescription: String

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    init(item: Item) {
        self.item = item
        _draftTitle = State(initialValue: item.title)
        _draftDescription = State(initialValue: item.markdownDescription)
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
        item.updatedAt = .now
        dismiss()
    }
}

private struct DeletedTaskSnapshot {
    let id: UUID
    let title: String
    let markdownDescription: String
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?

    init(item: Item) {
        id = item.id
        title = item.title
        markdownDescription = item.markdownDescription
        isCompleted = item.isCompleted
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
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt
        )
    }
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
