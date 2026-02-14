//
//  MeView.swift
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct MeView: View {
    @Environment(AppSettingsStore.self) private var appSettings
    @Environment(\.colorScheme) private var colorScheme
    @Query private var items: [Item]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var alertMessage: String?

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                profileCard
                statsCard
                settingsEntryCard
            }
            .padding(.horizontal, 18)
            .padding(.vertical, theme.spacing.md)
        }
        .background(
            LinearGradient(
                colors: [theme.colors.gradientTop, theme.colors.gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("我")
        .task {
            avatarImage = await AvatarStorage.shared.loadImage()
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await updateAvatar(with: newValue)
            }
        }
        .alert("头像更新失败", isPresented: Binding(get: {
            alertMessage != nil
        }, set: { shouldShow in
            if !shouldShow {
                alertMessage = nil
            }
        })) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "请稍后重试")
        }
    }

    private var profileCard: some View {
        VStack(spacing: theme.spacing.md) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(theme.colors.accent)
                                .padding(8)
                        }
                    }
                    .frame(width: 108, height: 108)
                    .clipShape(.circle)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.border, lineWidth: 1.5)
                    )

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.colors.accent)
                        .background(Circle().fill(.white))
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text("我的账户")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("本地设备配置")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }

    private var statsCard: some View {
        let stats = taskStats()
        return VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("统计")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.sm) {
                StatTile(title: "总任务", value: "\(stats.total)", theme: theme)
                StatTile(title: "未完成", value: "\(stats.active)", theme: theme)
                StatTile(
                    title: "已完成",
                    value: appSettings.showCompletedInStats ? "\(stats.completed)" : "隐藏",
                    theme: theme
                )
                StatTile(title: "今日到期", value: "\(stats.todayDue)", theme: theme)
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }

    private var settingsEntryCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("设置")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textSecondary)

            NavigationLink {
                SettingsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("偏好与系统设置")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textPrimary)
                        Text("主题、提醒、数据管理、关于")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .fill(theme.colors.mutedSurface)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }

    private func taskStats() -> (total: Int, active: Int, completed: Int, todayDue: Int) {
        let total = items.count
        let active = items.filter { !$0.isCompleted }.count
        let completed = items.filter(\.isCompleted).count
        let todayDue = items.filter {
            guard let dueAt = $0.dueAt else { return false }
            return Calendar.current.isDateInToday(dueAt)
        }.count
        return (total, active, completed, todayDue)
    }

    private func updateAvatar(with item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let compressed = image.jpegData(compressionQuality: 0.8) else {
            await MainActor.run {
                alertMessage = "无法读取所选图片，请更换图片后重试。"
            }
            return
        }

        do {
            _ = try await AvatarStorage.shared.save(imageData: compressed)
            await MainActor.run {
                avatarImage = UIImage(data: compressed)
                appSettings.avatarFileName = "avatar.jpg"
                appSettings.lastAvatarUpdatedAt = .now
            }
        } catch {
            await MainActor.run {
                alertMessage = "保存头像失败：\(error.localizedDescription)"
            }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            Text(value)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .fill(theme.colors.mutedSurface)
        )
    }
}
