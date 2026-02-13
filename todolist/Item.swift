//
//  Item.swift
//  todolist
//
//  Created by 梁庆卫 on 2026/2/13.
//

import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var markdownDescription: String
    var isCompleted: Bool
    var dueAt: Date?
    var priority: TaskPriority
    var tags: [String]
    var isFlagged: Bool
    var reminderEnabled: Bool
    var reminderOffsetMinutes: Int
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        markdownDescription: String = "",
        isCompleted: Bool = false,
        dueAt: Date? = nil,
        priority: TaskPriority = .medium,
        tags: [String] = [],
        isFlagged: Bool = false,
        reminderEnabled: Bool = false,
        reminderOffsetMinutes: Int = 30,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.markdownDescription = markdownDescription
        self.isCompleted = isCompleted
        self.dueAt = dueAt
        self.priority = priority
        self.tags = tags
        self.isFlagged = isFlagged
        self.reminderEnabled = reminderEnabled
        self.reminderOffsetMinutes = reminderOffsetMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var reminderConfig: ReminderConfig {
        ReminderConfig(isEnabled: reminderEnabled, offsetMinutes: reminderOffsetMinutes)
    }
}
