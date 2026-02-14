//
//  SettingsView.swift
//

import SwiftData
import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @Environment(AppSettingsStore.self) private var appSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query private var items: [Item]

    @State private var notificationStatus: String = "检查中..."
    @State private var showClearCompletedConfirm = false
    @State private var showClearAllConfirm = false
    @State private var showPrivacySheet = false
    @State private var showMailError = false

    var body: some View {
        Form {
            appearanceSection
            reminderSection
            dataManagementSection
            aboutSection
        }
        .navigationTitle("设置")
        .task {
            await refreshNotificationStatus()
        }
        .alert("无法打开邮件应用", isPresented: $showMailError) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("请在设备上配置邮件应用后再试。")
        }
        .sheet(isPresented: $showPrivacySheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("隐私说明")
                            .font(.title2.bold())
                        Text("本应用默认仅在本机存储任务与设置数据，不会主动上传到远端服务器。头像图片仅用于本地展示。")
                        Text("若启用提醒，系统会在本机调度本地通知。")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("关闭") {
                            showPrivacySheet = false
                        }
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            Picker("主题", selection: themeModeBinding) {
                ForEach(AppThemeMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Toggle("统计里显示已完成任务", isOn: showCompletedInStatsBinding)
        }
    }

    private var reminderSection: some View {
        Section("提醒") {
            HStack {
                Text("通知权限")
                Spacer()
                Text(notificationStatus)
                    .foregroundStyle(.secondary)
            }

            Picker("默认提醒偏移", selection: defaultReminderOffsetBinding) {
                Text("10 分钟前").tag(10)
                Text("30 分钟前").tag(30)
                Text("1 小时前").tag(60)
                Text("1 天前").tag(24 * 60)
            }
            .pickerStyle(.menu)

            Button("前往系统设置") {
                openSystemSettings()
            }
        }
    }

    private var dataManagementSection: some View {
        Section("数据管理") {
            Button("清空已完成任务", role: .destructive) {
                showClearCompletedConfirm = true
            }
            .confirmationDialog("确认清空已完成任务？", isPresented: $showClearCompletedConfirm, titleVisibility: .visible) {
                Button("清空", role: .destructive) {
                    clearCompletedTasks()
                }
                Button("取消", role: .cancel) {}
            }

            Button("清空全部任务", role: .destructive) {
                showClearAllConfirm = true
            }
            .confirmationDialog("确认清空全部任务？", isPresented: $showClearAllConfirm, titleVisibility: .visible) {
                Button("清空全部", role: .destructive) {
                    clearAllTasks()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Button("隐私说明") {
                showPrivacySheet = true
            }

            Button("发送反馈") {
                guard let url = URL(string: "mailto:support@example.com?subject=todolist%20feedback") else { return }
                openURL(url) { accepted in
                    if !accepted {
                        showMailError = true
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
        #endif
    }

    private func clearCompletedTasks() {
        for item in items where item.isCompleted {
            modelContext.delete(item)
        }
        try? modelContext.save()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func clearAllTasks() {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status: String
        switch settings.authorizationStatus {
        case .authorized:
            status = "已授权"
        case .denied:
            status = "未授权"
        case .notDetermined:
            status = "未决定"
        case .provisional:
            status = "临时授权"
        case .ephemeral:
            status = "临时会话"
        @unknown default:
            status = "未知"
        }
        await MainActor.run {
            notificationStatus = status
        }
    }

    private var themeModeBinding: Binding<AppThemeMode> {
        Binding(
            get: { appSettings.themeMode },
            set: { appSettings.themeMode = $0 }
        )
    }

    private var showCompletedInStatsBinding: Binding<Bool> {
        Binding(
            get: { appSettings.showCompletedInStats },
            set: { appSettings.showCompletedInStats = $0 }
        )
    }

    private var defaultReminderOffsetBinding: Binding<Int> {
        Binding(
            get: { appSettings.defaultReminderOffsetMinutes },
            set: { appSettings.defaultReminderOffsetMinutes = $0 }
        )
    }
}
