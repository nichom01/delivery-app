import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = LoginViewModel()
    @FocusState private var focus: Field?

    enum Field { case username, password }

    var body: some View {
        ZStack {
            DS.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    // Hero
                    VStack(spacing: DS.Spacing.md) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(DS.Colors.accent)

                        Text("Delivery Driver")
                            .font(DS.Typography.hero())
                            .foregroundColor(DS.Colors.textPrimary)

                        Text("Sign in to start your shift")
                            .font(DS.Typography.body())
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .padding(.top, 60)

                    // Form
                    VStack(spacing: DS.Spacing.md) {
                        DDTextField(
                            placeholder: "Username",
                            text: $vm.username,
                            icon: "person"
                        )
                        .focused($focus, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                        DDTextField(
                            placeholder: "Password",
                            text: $vm.password,
                            icon: "lock",
                            isSecure: true
                        )
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submitLogin() }

                        if let error = vm.errorMessage {
                            inlineError(error)
                        }

                        Button {
                            submitLogin()
                        } label: {
                            Group {
                                if vm.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Log In")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(isLoading: vm.isLoading))
                        .disabled(vm.isLoading)

                        demoButton
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.xl)
                }
            }
        }
    }

    // MARK: - Helpers

    private var demoButton: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack {
                Rectangle().fill(DS.Colors.divider).frame(height: 1)
                Text("or")
                    .font(DS.Typography.micro())
                    .foregroundColor(DS.Colors.textSecondary)
                    .fixedSize()
                Rectangle().fill(DS.Colors.divider).frame(height: 1)
            }

            Button {
                vm.loginAsDemo { appState.route = .main }
            } label: {
                Label("Try Demo Mode", systemImage: "flask.fill")
                    .font(DS.Typography.caption())
                    .foregroundColor(DS.Colors.accent)
            }
        }
    }

    private func submitLogin() {
        focus = nil
        Task { await vm.login { appState.route = .main } }
    }

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(DS.Colors.error)
            Text(message)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.sm)
        .background(DS.Colors.error.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.badge))
    }
}
