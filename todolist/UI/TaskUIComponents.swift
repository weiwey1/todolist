//
//  TaskUIComponents.swift
//  todolist
//

import SwiftUI

struct TaskInputCard: View {
    @Binding var text: String
    let onAdd: () -> Void
    let canAdd: Bool
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("快速添加")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            HStack(spacing: theme.spacing.sm) {
                TextField("输入任务标题", text: $text)
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
                            .stroke(theme.colors.border, lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .onSubmit(onAdd)
                    .accessibilityIdentifier("taskInputField")

                Button(action: onAdd) {
                    Text("添加")
                        .font(theme.typography.section)
                        .foregroundStyle(.white)
                        .frame(minWidth: 64)
                        .padding(.vertical, theme.spacing.sm)
                        .padding(.horizontal, theme.spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                                .fill(canAdd ? theme.colors.accent : theme.colors.textSecondary.opacity(0.35))
                        )
                }
                .disabled(!canAdd)
                .keyboardShortcut("n", modifiers: [.command])
                .accessibilityIdentifier("taskAddButton")
            }
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }
}

struct MainModeCard: View {
    @Binding var subTab: TaskSubTab
    @Binding var completionScope: TaskCompletionScope
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("视图")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            Picker("视图", selection: $subTab) {
                ForEach(TaskSubTab.allCases) { target in
                    Text(target.title).tag(target)
                }
            }
            .pickerStyle(.segmented)
            .tint(theme.colors.accent)

            Picker("状态", selection: $completionScope) {
                ForEach(TaskCompletionScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .tint(theme.colors.accent)
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }
}

struct AdvancedFilterCard: View {
    @Binding var filterState: TaskFilterState
    @Binding var draftTagText: String
    let onAddTag: () -> Void
    let onRemoveTag: (String) -> Void
    let onClear: () -> Void
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("高级筛选")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("优先级")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                HStack(spacing: theme.spacing.sm) {
                    ForEach(TaskPriority.allCases) { priority in
                        Button(priority.title) {
                            togglePriority(priority)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(priorityColor(priority).opacity(filterState.priorities.contains(priority) ? 1 : 0.45))
                    }
                }
            }

            Picker("到期范围", selection: $filterState.dueRange) {
                ForEach(DueDateRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("标签（逗号分隔）")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                HStack(spacing: theme.spacing.sm) {
                    TextField("例如：工作, 个人", text: $draftTagText)
                        .textFieldStyle(.roundedBorder)
                    Button("添加", action: onAddTag)
                        .buttonStyle(.borderedProminent)
                        .tint(theme.colors.accent)
                }

                if !filterState.requiredTags.isEmpty {
                    FlowTagsView(
                        tags: filterState.requiredTags.sorted(),
                        onRemove: onRemoveTag,
                        theme: theme
                    )
                }
            }

            Button("清空筛选", role: .destructive, action: onClear)
                .buttonStyle(.plain)
                .font(theme.typography.caption)
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }

    private func togglePriority(_ priority: TaskPriority) {
        if filterState.priorities.contains(priority) {
            filterState.priorities.remove(priority)
        } else {
            filterState.priorities.insert(priority)
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return theme.colors.priorityLow
        case .medium:
            return theme.colors.priorityMedium
        case .high:
            return theme.colors.priorityHigh
        case .urgent:
            return theme.colors.priorityUrgent
        }
    }
}

struct TaskCardRow<Destination: View>: View {
    let item: Item
    let destination: Destination
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSelectToggle: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    let theme: AppTheme

    private var descriptionPreview: String? {
        let trimmed = item.markdownDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let plain = (try? AttributedString(markdown: trimmed))
            .map { String($0.characters) }
            ?? trimmed
        let compact = plain.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return compact.isEmpty ? nil : compact
    }

    var body: some View {
        Group {
            if isSelectionMode {
                Button(action: onSelectToggle) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    destination
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(item.isCompleted ? "设为未完成" : "完成") {
                onToggle()
            }
            .tint(item.isCompleted ? theme.colors.textSecondary : theme.colors.success)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            .tint(theme.colors.danger)
        }
        .accessibilityIdentifier("taskRow_\(item.id.uuidString)")
    }

    private var cardContent: some View {
        HStack(spacing: theme.spacing.md) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? theme.colors.accent : theme.colors.textSecondary)
            } else {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? theme.colors.success : theme.colors.textSecondary.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.sm) {
                    Text(item.title)
                        .font(theme.typography.body)
                        .foregroundStyle(item.isCompleted ? theme.colors.textSecondary : theme.colors.textPrimary)
                        .strikethrough(item.isCompleted, color: theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                    PriorityBadge(priority: item.priority, theme: theme)
                }

                if let descriptionPreview {
                    Text(descriptionPreview)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary.opacity(0.95))
                        .lineLimit(2)
                }

                HStack(spacing: theme.spacing.sm) {
                    if let dueText = dueText {
                        Text(dueText)
                            .font(theme.typography.caption)
                            .foregroundStyle(dueColor)
                    }
                    if !item.tags.isEmpty {
                        Text(item.tags.joined(separator: " · "))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isSelectionMode {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.colors.textSecondary.opacity(0.7))
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                .fill(item.isCompleted ? theme.colors.mutedSurface : theme.colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                .stroke(theme.colors.border, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(
            color: theme.shadows.card.color,
            radius: theme.shadows.card.radius,
            x: theme.shadows.card.x,
            y: theme.shadows.card.y
        )
    }

    private var dueText: String? {
        guard let dueAt = item.dueAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "截止 \(formatter.localizedString(for: dueAt, relativeTo: .now))"
    }

    private var dueColor: Color {
        switch TaskDomain.dueState(for: item.dueAt) {
        case .overdue:
            return theme.colors.overdue
        case .today:
            return theme.colors.dueToday
        case .future, .none:
            return theme.colors.textSecondary
        }
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority
    let theme: AppTheme

    var body: some View {
        Text(priority.title)
            .font(theme.typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, 4)
            .background(priorityColor, in: Capsule())
    }

    private var priorityColor: Color {
        switch priority {
        case .low:
            return theme.colors.priorityLow
        case .medium:
            return theme.colors.priorityMedium
        case .high:
            return theme.colors.priorityHigh
        case .urgent:
            return theme.colors.priorityUrgent
        }
    }
}

struct FlowTagsView: View {
    let tags: [String]
    let onRemove: (String) -> Void
    let theme: AppTheme

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: theme.spacing.sm)], spacing: theme.spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Button {
                    onRemove(tag)
                } label: {
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textPrimary)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, 6)
                    .background(theme.colors.mutedSurface, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct BatchActionBar: View {
    let selectedCount: Int
    let onComplete: () -> Void
    let onUncomplete: () -> Void
    let onDelete: () -> Void
    let onAddTag: () -> Void
    let onRemoveTag: () -> Void
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("已选中 \(selectedCount) 项")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textPrimary)

            HStack(spacing: theme.spacing.sm) {
                Button("完成", action: onComplete)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.colors.success)
                    .keyboardShortcut(.return, modifiers: [.command])
                Button("取消完成", action: onUncomplete)
                    .buttonStyle(.bordered)
                Button("加标签", action: onAddTag)
                    .buttonStyle(.bordered)
                Button("删标签", action: onRemoveTag)
                    .buttonStyle(.bordered)
                Button("删除", role: .destructive, action: onDelete)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.delete, modifiers: [.command])
            }
        }
        .padding(theme.spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }
}

struct UndoFloatingBar: View {
    let onUndo: () -> Void
    let theme: AppTheme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: "trash")
                .foregroundStyle(theme.colors.textSecondary)

            Text("任务已删除")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textPrimary)

            Spacer()

            Button("撤销", action: onUndo)
                .font(theme.typography.section)
                .foregroundStyle(.white)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius.pill, style: .continuous)
                        .fill(theme.colors.accent)
                )
                .accessibilityIdentifier("undoDeleteButton")
        }
        .padding(theme.spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.xl, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        )
        .shadow(
            color: theme.shadows.floating.color,
            radius: theme.shadows.floating.radius,
            x: theme.shadows.floating.x,
            y: theme.shadows.floating.y
        )
    }
}

struct EmptyStateCard: View {
    let theme: AppTheme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(theme.colors.accent)

            Text("还没有任务")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            Text("从上方输入框开始添加第一条任务。")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }
}

struct EditorCardSection<Content: View>: View {
    let title: String
    let theme: AppTheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            content
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }
}
