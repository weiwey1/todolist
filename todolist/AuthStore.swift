import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
final class AuthStore {
    var currentSession: AuthUserSession?
    var isLoading = false
    var lastErrorMessage: String?
    var screenState: AuthScreenState = .phoneInput
    var pendingPhoneNumber: String?

    var isAuthenticated: Bool { currentSession != nil }

    private let service: AuthService
    private let sessionStore: AuthSessionStore
    private var hasBootstrapped = false

    init(service: AuthService = MockAuthService(), sessionStore: AuthSessionStore = AuthSessionStore()) {
        self.service = service
        self.sessionStore = sessionStore
    }

    func bootstrap() {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        currentSession = sessionStore.loadSession()
        screenState = currentSession == nil ? .phoneInput : .idle
    }

    func requestOTP(phone: String) async {
        isLoading = true
        screenState = .submitting
        lastErrorMessage = nil

        defer { isLoading = false }

        do {
            let challenge = try await service.sendOTP(to: phone)
            pendingPhoneNumber = challenge.phoneNumber
            screenState = .codeInput
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            screenState = .phoneInput
        }
    }

    func verifyOTP(phone: String, code: String) async {
        isLoading = true
        screenState = .submitting
        lastErrorMessage = nil

        defer { isLoading = false }

        do {
            let sourcePhone = pendingPhoneNumber ?? phone
            let session = try await service.verifyOTP(phone: sourcePhone, code: code)
            guard sessionStore.saveSession(session) else {
                throw AuthError.persistenceFailed
            }
            currentSession = session
            pendingPhoneNumber = nil
            screenState = .idle
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            screenState = .codeInput
        }
    }

    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        screenState = .submitting
        lastErrorMessage = nil

        defer { isLoading = false }

        do {
            let session = try await service.signInWithApple(credential: credential)
            guard sessionStore.saveSession(session) else {
                throw AuthError.persistenceFailed
            }
            currentSession = session
            pendingPhoneNumber = nil
            screenState = .idle
        } catch {
            lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            screenState = .phoneInput
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        await service.signOut()
        sessionStore.clearSession()
        currentSession = nil
        pendingPhoneNumber = nil
        screenState = .phoneInput
        lastErrorMessage = nil
    }
}
