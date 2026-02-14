import AuthenticationServices

protocol AuthService {
    func sendOTP(to phone: String) async throws -> OTPChallenge
    func verifyOTP(phone: String, code: String) async throws -> AuthUserSession
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AuthUserSession
    func signOut() async
}
