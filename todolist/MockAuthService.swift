import AuthenticationServices
import Foundation

struct MockAuthService: AuthService {
    private static let otpCode = "123456"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func sendOTP(to phone: String) async throws -> OTPChallenge {
        guard let normalized = AuthDomain.normalizedPhoneNumber(phone) else {
            throw AuthError.invalidPhoneNumber
        }

        defaults.set(normalized, forKey: challengePhoneKey(for: normalized))
        let now = Date()
        return OTPChallenge(
            phoneNumber: normalized,
            expiresAt: now.addingTimeInterval(5 * 60),
            resendAfter: now.addingTimeInterval(30)
        )
    }

    func verifyOTP(phone: String, code: String) async throws -> AuthUserSession {
        guard let normalized = AuthDomain.normalizedPhoneNumber(phone) else {
            throw AuthError.invalidPhoneNumber
        }

        guard defaults.string(forKey: challengePhoneKey(for: normalized)) != nil else {
            throw AuthError.challengeNotFound
        }

        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed == Self.otpCode else {
            throw AuthError.invalidVerificationCode
        }

        return AuthUserSession(
            userID: "phone:\(normalized)",
            provider: .phone,
            displayName: "手机用户",
            phoneNumber: normalized,
            email: nil,
            createdAt: .now
        )
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AuthUserSession {
        let session = makeAppleSession(
            userID: credential.user,
            email: credential.email,
            fullName: credential.fullName
        )
        cacheAppleProfile(for: session)
        return session
    }

    func signOut() async {
    }

    func makeAppleSession(userID: String, email: String?, fullName: PersonNameComponents?) -> AuthUserSession {
        let profile = cachedAppleProfile(userID: userID)
        let resolvedEmail = email ?? profile?.email

        let formattedName = fullName.flatMap { PersonNameComponentsFormatter().string(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let resolvedName: String?
        if let formattedName, !formattedName.isEmpty {
            resolvedName = formattedName
        } else {
            resolvedName = profile?.displayName ?? "Apple 用户"
        }

        return AuthUserSession(
            userID: userID,
            provider: .apple,
            displayName: resolvedName,
            phoneNumber: nil,
            email: resolvedEmail,
            createdAt: .now
        )
    }

    private func challengePhoneKey(for phone: String) -> String {
        "auth.challenge.phone.\(phone)"
    }

    private func appleProfileKey(userID: String) -> String {
        "auth.apple.profile.\(userID)"
    }

    private func cacheAppleProfile(for session: AuthUserSession) {
        let payload = AppleProfile(displayName: session.displayName, email: session.email)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: appleProfileKey(userID: session.userID))
    }

    private func cachedAppleProfile(userID: String) -> AppleProfile? {
        guard let data = defaults.data(forKey: appleProfileKey(userID: userID)) else { return nil }
        return try? JSONDecoder().decode(AppleProfile.self, from: data)
    }
}

private struct AppleProfile: Codable {
    var displayName: String?
    var email: String?
}
