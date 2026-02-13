//
//  TaskDomain.swift
//  todolist
//

import Foundation

enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case completed

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .active:
            return "未完成"
        case .completed:
            return "已完成"
        }
    }
}

enum TaskDomain {
    static func normalizedTitle(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func normalizedMarkdownDescription(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func split(items: [Item], filter: TaskFilter) -> (active: [Item], completed: [Item]) {
        let filtered: [Item]
        switch filter {
        case .all:
            filtered = items
        case .active:
            filtered = items.filter { !$0.isCompleted }
        case .completed:
            filtered = items.filter { $0.isCompleted }
        }

        let active = filtered.filter { !$0.isCompleted }
        let completed = filtered.filter { $0.isCompleted }
        return (active, completed)
    }
}
