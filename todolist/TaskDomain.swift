//
//  TaskDomain.swift
//

import Foundation

enum MainViewMode: String, CaseIterable, Identifiable {
    case list
    case calendar

    var id: Self { self }

    var title: String {
        switch self {
        case .list:
            return "列表"
        case .calendar:
            return "日历"
        }
    }
}

enum TaskPriority: Int, CaseIterable, Codable, Identifiable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    var id: Self { self }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        case .urgent:
            return "紧急"
        }
    }
}

enum TaskSortMode: String, CaseIterable, Identifiable {
    case dueDateFirst

    var id: Self { self }
}

enum TaskCompletionScope: String, CaseIterable, Identifiable {
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

enum DueDateRange: String, CaseIterable, Identifiable {
    case any
    case overdue
    case today
    case thisWeek
    case noDueDate

    var id: Self { self }

    var title: String {
        switch self {
        case .any:
            return "任意"
        case .overdue:
            return "已逾期"
        case .today:
            return "今天"
        case .thisWeek:
            return "本周"
        case .noDueDate:
            return "无截止"
        }
    }
}

enum CalendarScope: String, CaseIterable, Identifiable {
    case week
    case month

    var id: Self { self }

    var title: String {
        switch self {
        case .week:
            return "周"
        case .month:
            return "月"
        }
    }
}

struct ReminderConfig: Codable, Equatable {
    var isEnabled: Bool
    var offsetMinutes: Int
}

struct TaskFilterState: Equatable {
    var completion: TaskCompletionScope = .all
    var priorities: Set<TaskPriority> = []
    var requiredTags: Set<String> = []
    var dueRange: DueDateRange = .any
}

enum DueState {
    case overdue
    case today
    case future
    case none
}

enum TaskDomain {
    static func normalizedTitle(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func normalizedMarkdownDescription(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedTags(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func dueState(for dueAt: Date?, now: Date = .now, calendar: Calendar = .current) -> DueState {
        guard let dueAt else { return .none }
        if calendar.isDateInToday(dueAt) {
            return .today
        }
        if dueAt < now {
            return .overdue
        }
        return .future
    }

    static func matchesDueRange(
        _ range: DueDateRange,
        dueAt: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        switch range {
        case .any:
            return true
        case .overdue:
            guard let dueAt else { return false }
            return dueAt < now && !calendar.isDateInToday(dueAt)
        case .today:
            guard let dueAt else { return false }
            return calendar.isDateInToday(dueAt)
        case .thisWeek:
            guard let dueAt else { return false }
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
            guard let weekInterval else { return false }
            return weekInterval.contains(dueAt)
        case .noDueDate:
            return dueAt == nil
        }
    }

    static func reminderDate(for dueAt: Date, config: ReminderConfig) -> Date {
        dueAt.addingTimeInterval(TimeInterval(-config.offsetMinutes * 60))
    }
}

enum TaskQueryService {
    static func split(
        items: [Item],
        filter: TaskFilterState,
        sortMode: TaskSortMode = .dueDateFirst
    ) -> (active: [Item], completed: [Item]) {
        let filtered = items.filter { item in
            completionMatch(item: item, filter: filter.completion) &&
            priorityMatch(item: item, priorities: filter.priorities) &&
            tagsMatch(item: item, requiredTags: filter.requiredTags) &&
            TaskDomain.matchesDueRange(filter.dueRange, dueAt: item.dueAt)
        }

        let active = filtered
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                switch sortMode {
                case .dueDateFirst:
                    return compareActive(lhs: lhs, rhs: rhs)
                }
            }

        let completed = filtered
            .filter(\.isCompleted)
            .sorted { lhs, rhs in
                let left = lhs.completedAt ?? lhs.updatedAt
                let right = rhs.completedAt ?? rhs.updatedAt
                return left > right
            }

        return (active, completed)
    }

    private static func completionMatch(item: Item, filter: TaskCompletionScope) -> Bool {
        switch filter {
        case .all:
            return true
        case .active:
            return !item.isCompleted
        case .completed:
            return item.isCompleted
        }
    }

    private static func priorityMatch(item: Item, priorities: Set<TaskPriority>) -> Bool {
        priorities.isEmpty || priorities.contains(item.priority)
    }

    private static func tagsMatch(item: Item, requiredTags: Set<String>) -> Bool {
        guard !requiredTags.isEmpty else { return true }
        let itemTags = Set(item.tags.map { $0.lowercased() })
        return requiredTags.allSatisfy { itemTags.contains($0.lowercased()) }
    }

    private static func compareActive(lhs: Item, rhs: Item) -> Bool {
        switch (lhs.dueAt, rhs.dueAt) {
        case (.some(let leftDue), .some(let rightDue)) where leftDue != rightDue:
            return leftDue < rightDue
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            break
        }

        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }
}
