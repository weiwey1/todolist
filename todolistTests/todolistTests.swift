//
//  todolistTests.swift
//  todolistTests
//
//  Created by 梁庆卫 on 2026/2/13.
//

import Foundation
import SwiftData
import Testing
@testable import todolist

struct todolistTests {

    @Test
    func normalizedTitleRejectsBlankInput() {
        #expect(TaskDomain.normalizedTitle("") == nil)
        #expect(TaskDomain.normalizedTitle("   \n\t") == nil)
        #expect(TaskDomain.normalizedTitle("  买牛奶  ") == "买牛奶")
        #expect(TaskDomain.normalizedMarkdownDescription("  **重点**  ") == "**重点**")
        #expect(TaskDomain.normalizedTags("工作, 个人,  紧急 ") == ["工作", "个人", "紧急"])
    }

    @Test
    func splitByFilterReturnsExpectedRows() {
        let active = Item(title: "active", isCompleted: false)
        let completed = Item(title: "completed", isCompleted: true, priority: .high)
        completed.completedAt = .now
        let items = [active, completed]
        var filter = TaskFilterState()

        let all = TaskQueryService.split(items: items, filter: filter)
        #expect(all.active.count == 1)
        #expect(all.completed.count == 1)

        filter.completion = .active
        let activeOnly = TaskQueryService.split(items: items, filter: filter)
        #expect(activeOnly.active.count == 1)
        #expect(activeOnly.completed.isEmpty)

        filter.completion = .completed
        let completedOnly = TaskQueryService.split(items: items, filter: filter)
        #expect(completedOnly.active.isEmpty)
        #expect(completedOnly.completed.count == 1)
    }

    @Test
    func dueDatePrioritySortWorks() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        let noDueUrgent = Item(title: "urgent no due", dueAt: nil, priority: .urgent, createdAt: now)
        let dueHigh = Item(title: "high due", dueAt: now, priority: .high, createdAt: now)
        let dueLow = Item(title: "low due", dueAt: now, priority: .low, createdAt: later)

        let result = TaskQueryService.split(items: [noDueUrgent, dueLow, dueHigh], filter: TaskFilterState())
        #expect(result.active.first?.title == "high due")
        #expect(result.active.last?.title == "urgent no due")
    }

    @Test
    func dueRangeFilterWorks() {
        let now = Date()
        let overdue = Item(title: "overdue", dueAt: now.addingTimeInterval(-86400))
        let today = Item(title: "today", dueAt: now.addingTimeInterval(3600))
        let noDue = Item(title: "none", dueAt: nil)

        var filter = TaskFilterState()
        filter.dueRange = .overdue
        let overdueResult = TaskQueryService.split(items: [overdue, today, noDue], filter: filter)
        #expect(overdueResult.active.count == 1)
        #expect(overdueResult.active.first?.title == "overdue")

        filter.dueRange = .noDueDate
        let noDueResult = TaskQueryService.split(items: [overdue, today, noDue], filter: filter)
        #expect(noDueResult.active.count == 1)
        #expect(noDueResult.active.first?.title == "none")
    }

    @Test
    func completionTimestampTracksState() {
        let item = Item(title: "task")
        #expect(item.completedAt == nil)

        item.isCompleted = true
        item.completedAt = .now
        #expect(item.completedAt != nil)

        item.isCompleted = false
        item.completedAt = nil
        #expect(item.completedAt == nil)
    }

    @Test
    func itemPersistsInMemoryContainer() throws {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let item = Item(title: "买牛奶")
        context.insert(item)
        try context.save()

        let descriptor = FetchDescriptor<Item>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "买牛奶")
    }

}
