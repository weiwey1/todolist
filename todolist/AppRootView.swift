import SwiftUI

struct AppRootView: View {
    @Environment(AuthStore.self) private var authStore

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                RootTabView()
            } else {
                LoginView()
            }
        }
        .task {
            authStore.bootstrap()
        }
    }
}

#Preview {
    AppRootView()
        .environment(AuthStore())
        .environment(AppSettingsStore())
}
