//
//  ReminderService.swift
//

import Foundation
import UserNotifications

final class ReminderService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted
        @unknown default:
            return false
        }
    }

    func schedule(for item: Item) async {
        await cancel(for: item.id)

        let config = item.reminderConfig
        guard config.isEnabled, let dueAt = item.dueAt else { return }

        let authorized = await requestAuthorizationIfNeeded()
        guard authorized else { return }

        var reminderDate = TaskDomain.reminderDate(for: dueAt, config: config)
        if reminderDate <= .now, dueAt > .now {
            reminderDate = dueAt
        }
        guard reminderDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "任务提醒"
        content.body = item.title
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: notificationIdentifier(for: item.id), content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(for itemID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: itemID)])
    }

    func rebuild(for items: [Item]) async {
        for item in items {
            await schedule(for: item)
        }
    }

    private func notificationIdentifier(for itemID: UUID) -> String {
        "task.reminder.\(itemID.uuidString)"
    }
}
