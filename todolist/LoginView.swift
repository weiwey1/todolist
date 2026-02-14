import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showErrorAlert = false

    private var theme: AppTheme {
        AppTheme.resolve(for: colorScheme)
    }

    private var canSendCode: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !authStore.isLoading
    }

    private var canVerify: Bool {
        !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !authStore.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    titleSection
                    phoneCard
                    appleCard
                    hintCard
                }
                .padding(.horizontal, 18)
                .padding(.vertical, theme.spacing.lg)
            }
            .background(
                LinearGradient(
                    colors: [theme.colors.gradientTop, theme.colors.gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("登录")
            .onChange(of: authStore.lastErrorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .alert("登录失败", isPresented: $showErrorAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(authStore.lastErrorMessage ?? "请稍后重试")
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("欢迎使用 todolist")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
            Text("请先登录后继续使用任务功能")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var phoneCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("手机号验证码登录")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textPrimary)

            TextField("请输入手机号", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(theme.spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .fill(theme.colors.mutedSurface)
                )
                .accessibilityIdentifier("loginPhoneField")

            Button {
                Task {
                    await authStore.requestOTP(phone: phoneNumber)
                }
            } label: {
                HStack {
                    if authStore.isLoading && authStore.screenState == .submitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("获取验证码")
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.colors.accent)
            .disabled(!canSendCode)
            .accessibilityIdentifier("sendOtpButton")

            if authStore.screenState == .codeInput || authStore.pendingPhoneNumber != nil {
                TextField("请输入验证码（开发期固定 123456）", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(theme.spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                            .fill(theme.colors.mutedSurface)
                    )
                    .accessibilityIdentifier("otpCodeField")

                Button {
                    Task {
                        await authStore.verifyOTP(phone: phoneNumber, code: verificationCode)
                    }
                } label: {
                    HStack {
                        if authStore.isLoading && authStore.screenState == .submitting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("验证码登录")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canVerify)
                .accessibilityIdentifier("otpLoginButton")
            }

            if let error = authStore.lastErrorMessage {
                Text(error)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.danger)
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }

    private var appleCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Apple 登录")
                .font(theme.typography.section)
                .foregroundStyle(theme.colors.textPrimary)

            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                            authStore.lastErrorMessage = AuthError.unsupportedCredential.localizedDescription
                            return
                        }
                        Task {
                            await authStore.handleAppleSignIn(credential: credential)
                        }
                    case .failure:
                        authStore.lastErrorMessage = AuthError.appleAuthorizationFailed.localizedDescription
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 46)
            .clipShape(.rect(cornerRadius: theme.radius.md))
            .disabled(authStore.isLoading)
            .accessibilityIdentifier("appleSignInButton")
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme, elevated: true)
    }

    private var hintCard: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(theme.colors.textSecondary)
            Text("开发环境：验证码固定为 123456")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity)
        .appCardStyle(theme: theme)
    }
}
