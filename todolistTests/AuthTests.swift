import Foundation
import Testing
@testable import todolist

struct AuthTests {

    @Test
    func phoneNormalizationSupportsDefaultRegionAndIntl() {
        #expect(AuthDomain.normalizedPhoneNumber("13800138000") == "+8613800138000")
        #expect(AuthDomain.normalizedPhoneNumber("+1 415-555-1234") == "+14155551234")
        #expect(AuthDomain.normalizedPhoneNumber("abc") == nil)
        #expect(AuthDomain.normalizedPhoneNumber("123") == nil)
    }

    @Test
    func otpVerificationSucceedsWithExpectedCode() async throws {
        let suite = "auth.tests.otp.success.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = MockAuthService(defaults: defaults)
        _ = try await service.sendOTP(to: "13800138000")
        let session = try await service.verifyOTP(phone: "13800138000", code: "123456")

        #expect(session.provider == .phone)
        #expect(session.phoneNumber == "+8613800138000")
    }

    @Test
    func otpVerificationFailsWithWrongCode() async throws {
        let suite = "auth.tests.otp.fail.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = MockAuthService(defaults: defaults)
        _ = try await service.sendOTP(to: "13800138000")

        do {
            _ = try await service.verifyOTP(phone: "13800138000", code: "000000")
            Issue.record("Expected invalidVerificationCode")
        } catch {
            #expect(error as? AuthError == .invalidVerificationCode)
        }
    }

    @Test
    func sessionStorePersistsAndClears() {
        let suite = "auth.tests.store.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AuthSessionStore(defaults: defaults)
        let session = AuthUserSession(
            userID: "user-1",
            provider: .phone,
            displayName: "Tester",
            phoneNumber: "+8613800138000",
            email: nil,
            createdAt: .now
        )

        #expect(store.saveSession(session) == true)
        #expect(store.loadSession() == session)

        store.clearSession()
        #expect(store.loadSession() == nil)
    }

    @Test
    @MainActor
    func authStoreSignOutClearsState() async {
        let suite = "auth.tests.store.signout.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = MockAuthService(defaults: defaults)
        let store = AuthStore(service: service, sessionStore: AuthSessionStore(defaults: defaults))

        await store.requestOTP(phone: "13800138000")
        await store.verifyOTP(phone: "13800138000", code: "123456")
        #expect(store.isAuthenticated == true)

        await store.signOut()
        #expect(store.isAuthenticated == false)
        #expect(AuthSessionStore(defaults: defaults).loadSession() == nil)
    }

    @Test
    func appleSessionFallsBackToCachedProfileWhenMissingFields() {
        let suite = "auth.tests.apple.cache.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = MockAuthService(defaults: defaults)
        var name = PersonNameComponents()
        name.givenName = "Wei"
        name.familyName = "Liang"
        let first = service.makeAppleSession(userID: "apple-user", email: "first@example.com", fullName: name)
        #expect(first.email == "first@example.com")
        #expect(first.displayName?.contains("Wei") == true)

        let cachedPayload = [
            "displayName": first.displayName ?? "",
            "email": first.email ?? ""
        ]
        defaults.set(try? JSONEncoder().encode(cachedPayload), forKey: "auth.apple.profile.apple-user")
        let second = service.makeAppleSession(userID: "apple-user", email: nil, fullName: nil)

        #expect(second.email == "first@example.com")
        #expect(second.displayName == first.displayName)
    }
}
