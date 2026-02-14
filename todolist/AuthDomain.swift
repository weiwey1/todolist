import Foundation

enum AuthProvider: String, Codable, Equatable {
    case phone
    case apple

    var title: String {
        switch self {
        case .phone:
            return "手机号"
        case .apple:
            return "Apple"
        }
    }
}

struct AuthUserSession: Codable, Equatable {
    var userID: String
    var provider: AuthProvider
    var displayName: String?
    var phoneNumber: String?
    var email: String?
    var createdAt: Date
}

struct OTPChallenge: Codable, Equatable {
    var phoneNumber: String
    var expiresAt: Date
    var resendAfter: Date
}

enum AuthScreenState: Equatable {
    case phoneInput
    case codeInput
    case submitting
    case idle
}

enum AuthError: LocalizedError, Equatable {
    case invalidPhoneNumber
    case invalidVerificationCode
    case challengeNotFound
    case appleAuthorizationFailed
    case persistenceFailed
    case unsupportedCredential

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "手机号格式不正确，请检查后重试。"
        case .invalidVerificationCode:
            return "验证码错误，请输入 123456 重试。"
        case .challengeNotFound:
            return "请先获取验证码。"
        case .appleAuthorizationFailed:
            return "Apple 登录失败，请重试。"
        case .persistenceFailed:
            return "登录状态保存失败，请重试。"
        case .unsupportedCredential:
            return "不支持的 Apple 授权凭证。"
        }
    }
}

enum AuthDomain {
    static let fallbackRegionCode = "+86"

    static func normalizedPhoneNumber(_ rawValue: String, defaultRegionCode: String = fallbackRegionCode) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let compact = trimmed.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if compact.hasPrefix("+") {
            let digits = String(compact.dropFirst())
            guard digits.allSatisfy(\.isNumber), (6...15).contains(digits.count) else { return nil }
            return "+\(digits)"
        }

        guard compact.allSatisfy(\.isNumber), (6...15).contains(compact.count) else { return nil }
        return "\(defaultRegionCode)\(compact)"
    }

    static func maskedPhoneNumber(_ value: String?) -> String {
        guard let value else { return "未绑定" }
        let digits = value.filter(\.isNumber)
        guard digits.count >= 7 else { return value }

        let prefix = String(digits.prefix(3))
        let suffix = String(digits.suffix(4))
        return "\(prefix)****\(suffix)"
    }
}
