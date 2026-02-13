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
                .accessibilityIdentifier("taskAddButton")
            }
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }
}

struct FilterSegmentCard: View {
    @Binding var selectedFilter: TaskFilter
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("筛选")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            Picker("筛选", selection: $selectedFilter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .tint(theme.colors.accent)
            .pickerStyle(.segmented)
        }
        .padding(theme.spacing.lg)
        .appCardStyle(theme: theme, elevated: true)
    }
}

struct TaskCardRow<Destination: View>: View {
    let item: Item
    let destination: Destination
    let onToggle: () -> Void
    let onDelete: () -> Void
    let theme: AppTheme

    private var statusText: String {
        item.isCompleted ? "已完成" : "待完成"
    }

    private var descriptionPreview: String? {
        let trimmed = item.markdownDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let rendered = try? AttributedString(markdown: trimmed) {
            let plain = String(rendered.characters)
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return plain.isEmpty ? nil : plain
        }

        return trimmed.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(item.isCompleted ? theme.colors.success : theme.colors.textSecondary.opacity(0.85))
                    .symbolEffect(.pulse, value: item.isCompleted)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(item.title)
                        .font(theme.typography.body)
                        .foregroundStyle(item.isCompleted ? theme.colors.textSecondary : theme.colors.textPrimary)
                        .strikethrough(item.isCompleted, color: theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)

                    if let descriptionPreview {
                        Text(descriptionPreview)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary.opacity(0.95))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Text(statusText)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.colors.textSecondary.opacity(0.7))
            }
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .fill(item.isCompleted ? theme.colors.mutedSurface : theme.colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
            .shadow(
                color: theme.shadows.card.color,
                radius: theme.shadows.card.radius,
                x: theme.shadows.card.x,
                y: theme.shadows.card.y
            )
        }
        .buttonStyle(.plain)
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

#Preview("UI Components - Light") {
    let theme = AppTheme.light
    return VStack(spacing: theme.spacing.md) {
        TaskInputCard(
            text: .constant("写晨间计划"),
            onAdd: {},
            canAdd: true,
            theme: theme
        )
        FilterSegmentCard(selectedFilter: .constant(.all), theme: theme)
        EmptyStateCard(theme: theme)
        UndoFloatingBar(onUndo: {}, theme: theme)
    }
    .padding()
    .background(theme.colors.background)
}
