//
//  todolistApp.swift
//  todolist
//
//  Created by 梁庆卫 on 2026/2/13.
//

import SwiftUI
import SwiftData
import UserNotifications

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }
}

@main
struct todolistApp: App {
    private let notificationDelegate = NotificationCenterDelegate()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        return Self.makeContainer(schema: schema)
    }()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private extension todolistApp {
    static func makeContainer(schema: Schema) -> ModelContainer {
        let storeURL = storeURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    static func storeURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let storeDirectory = baseURL.appendingPathComponent("todolist", isDirectory: true)
        try? FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        return storeDirectory.appendingPathComponent("todolist.store")
    }
}
