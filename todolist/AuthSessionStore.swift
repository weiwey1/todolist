import Foundation

struct AuthSessionStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "auth.session.v1") {
        self.defaults = defaults
        self.key = key
    }

    func loadSession() -> AuthUserSession? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AuthUserSession.self, from: data)
    }

    @discardableResult
    func saveSession(_ session: AuthUserSession) -> Bool {
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: key)
            return true
        } catch {
            return false
        }
    }

    func clearSession() {
        defaults.removeObject(forKey: key)
    }
}
