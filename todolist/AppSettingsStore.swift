//
//  AppSettingsStore.swift
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSettingsStore {
    private enum Keys {
        static let themeMode = "settings.themeMode"
        static let defaultReminderOffsetMinutes = "settings.defaultReminderOffsetMinutes"
        static let avatarFileName = "settings.avatarFileName"
        static let lastAvatarUpdatedAt = "settings.lastAvatarUpdatedAt"
        static let showCompletedInStats = "settings.showCompletedInStats"
    }

    var themeMode: AppThemeMode {
        didSet { persistThemeMode() }
    }
    var defaultReminderOffsetMinutes: Int {
        didSet { persistDefaultReminderOffsetMinutes() }
    }
    var avatarFileName: String? {
        didSet { persistAvatarFileName() }
    }
    var lastAvatarUpdatedAt: Date? {
        didSet { persistLastAvatarUpdatedAt() }
    }
    var showCompletedInStats: Bool {
        didSet { persistShowCompletedInStats() }
    }

    private let defaults: UserDefaults
    private var isHydrating = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let raw = defaults.string(forKey: Keys.themeMode),
           let parsed = AppThemeMode(rawValue: raw) {
            themeMode = parsed
        } else {
            themeMode = .system
        }

        let storedReminderOffset = defaults.integer(forKey: Keys.defaultReminderOffsetMinutes)
        if storedReminderOffset == 0 {
            defaultReminderOffsetMinutes = 30
        } else {
            defaultReminderOffsetMinutes = storedReminderOffset
        }

        avatarFileName = defaults.string(forKey: Keys.avatarFileName)
        lastAvatarUpdatedAt = defaults.object(forKey: Keys.lastAvatarUpdatedAt) as? Date
        if defaults.object(forKey: Keys.showCompletedInStats) == nil {
            showCompletedInStats = true
        } else {
            showCompletedInStats = defaults.bool(forKey: Keys.showCompletedInStats)
        }

        isHydrating = false
    }

    private func persistThemeMode() {
        guard !isHydrating else { return }
        defaults.set(themeMode.rawValue, forKey: Keys.themeMode)
    }

    private func persistDefaultReminderOffsetMinutes() {
        guard !isHydrating else { return }
        defaults.set(defaultReminderOffsetMinutes, forKey: Keys.defaultReminderOffsetMinutes)
    }

    private func persistAvatarFileName() {
        guard !isHydrating else { return }
        defaults.set(avatarFileName, forKey: Keys.avatarFileName)
    }

    private func persistLastAvatarUpdatedAt() {
        guard !isHydrating else { return }
        defaults.set(lastAvatarUpdatedAt, forKey: Keys.lastAvatarUpdatedAt)
    }

    private func persistShowCompletedInStats() {
        guard !isHydrating else { return }
        defaults.set(showCompletedInStats, forKey: Keys.showCompletedInStats)
    }
}
