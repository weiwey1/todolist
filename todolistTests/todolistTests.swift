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
    }

    @Test
    func splitByFilterReturnsExpectedRows() {
        let active = Item(title: "active", isCompleted: false)
        let completed = Item(title: "completed", isCompleted: true)
        completed.completedAt = .now
        let items = [active, completed]

        let all = TaskDomain.split(items: items, filter: .all)
        #expect(all.active.count == 1)
        #expect(all.completed.count == 1)

        let activeOnly = TaskDomain.split(items: items, filter: .active)
        #expect(activeOnly.active.count == 1)
        #expect(activeOnly.completed.isEmpty)

        let completedOnly = TaskDomain.split(items: items, filter: .completed)
        #expect(completedOnly.active.isEmpty)
        #expect(completedOnly.completed.count == 1)
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
