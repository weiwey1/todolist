//
//  RootTabView.swift
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @State private var selectedTab: RootTab = .tasks

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("任务", systemImage: "checklist")
                }
                .tag(RootTab.tasks)

            NavigationStack {
                MeView()
            }
            .tabItem {
                Label("我", systemImage: "person.crop.circle")
            }
            .tag(RootTab.me)
        }
    }
}

#Preview {
    RootTabView()
        .environment(AppSettingsStore())
        .modelContainer(for: Item.self, inMemory: true)
}
