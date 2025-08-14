import BitwardenResources
import SwiftUI

// MARK: - TwoFactorAuthView

/// A view that prompts the user for a two-factor authentication code.
///
struct TwoFactorAuthView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<TwoFactorAuthState, TwoFactorAuthAction, TwoFactorAuthEffect>

    /// The text field configuration for the verification field.
    var verificationTextFieldConfiguration: TextFieldConfiguration {
        switch store.state.authMethod {
        case .yubiKey:
            TextFieldConfiguration.oneTimeCode(keyboardType: .default)
        default:
            TextFieldConfiguration.oneTimeCode()
        }
    }

    // MARK: View

    var body: some View {
        content
            .onChange(of: store.state.url) { newValue in
                guard let url = newValue else { return }
                openURL(url)
                store.send(.clearURL)
            }
            .toast(store.binding(
                get: \.toast,
                send: TwoFactorAuthAction.toastShown
            ))
            .navigationBar(title: store.state.titleText, titleDisplayMode: .inline)
            .task {
                await store.perform(.appeared)
            }
            .task(id: store.state.authMethod) {
                guard store.state.authMethod == .yubiKey else { return }
                await store.perform(.listenForNFC)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelToolbarButton {
                        store.send(.dismiss)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !store.state.deviceVerificationRequired {
                        authMethodsMenu
                    }
                }
            }
    }

    // MARK: Private Views

    /// The two-factor authentication menu buttons.
    private var authMethodsMenu: some View {
        optionsToolbarMenu {
            Menu(Localizations.useAnotherTwoStepMethod) {
                ForEach(store.state.availableAuthMethods) { method in
                    Button(method.title) {
                        store.send(.authMethodSelected(method))
                    }
                }
            }
        }
    }

    /// The main body content of the view
    @ViewBuilder private var content: some View {
        switch store.state.authMethod {
        case .duo,
             .duoOrganization:
            duo2FAView
        case .webAuthn:
            webAuthn2FAView
        default:
            defaultContent
        }
    }

    /// The continue button.
    private var continueButton: some View {
        AsyncButton(Localizations.continue) {
            await store.perform(.continueTapped)
        }
        .disabled(!store.state.continueEnabled)
        .buttonStyle(.primary())
    }

    /// The body content for most 2FA methods.
    private var defaultContent: some View {
        VStack(spacing: 24) {
            if let authMethodImage = store.state.authMethodImageAsset {
                Image(decorative: authMethodImage)
                    .resizable()
                    .frame(width: 124, height: 124)
            }

            detailText

            VStack(spacing: 8) {
                verificationCodeTextField

                if !store.state.deviceVerificationRequired {
                    rememberMeToggle
                }
            }

            VStack(spacing: 12) {
                continueButton

                resendEmailButton
            }
        }
        .padding(.top, 12)
        .scrollView()
    }

    /// The detailed instructions for the method.
    private var detailText: some View {
        VStack(spacing: 16) {
            Text(store.state.detailsText)
                .styleGuide(.body)
                .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)

            if let detailImageAsset = store.state.detailImageAsset {
                Image(decorative: detailImageAsset)
                    .resizable()
                    .frame(width: 124, height: 124)
            }
        }
    }

    /// The launch duo button.
    private var duoButton: some View {
        AsyncButton(Localizations.launchDuo) {
            await store.perform(.beginDuoAuth)
        }
        .buttonStyle(.primary())
    }

    /// A view for DUO 2FA type.
    @ViewBuilder private var duo2FAView: some View {
        VStack(spacing: 24) {
            detailText

            rememberMeToggle

            duoButton
        }
        .padding(.top, 12)
        .scrollView()
    }

    /// The launch webAuthn button.
    private var webAuthnButton: some View {
        AsyncButton(Localizations.launchWebAuthn) {
            await store.perform(.beginWebAuthn)
        }
        .buttonStyle(.primary())
    }

    /// A view for WebAuthn 2FA type.
    @ViewBuilder private var webAuthn2FAView: some View {
        VStack(spacing: 24) {
            detailText

            rememberMeToggle

            webAuthnButton
        }
        .padding(.top, 12)
        .scrollView()
    }

    /// The remember me toggle.
    private var rememberMeToggle: some View {
        BitwardenToggle(
            Localizations.rememberMe,
            isOn: store.binding(
                get: { $0.isRememberMeOn },
                send: { .rememberMeToggleChanged($0) }
            )
        )
        .contentBlock()
    }

    /// The resend email button for the email authentication option.
    @ViewBuilder private var resendEmailButton: some View {
        if store.state.authMethod == .email {
            AsyncButton(Localizations.resendCode) {
                await store.perform(.resendEmailTapped)
            }
            .buttonStyle(.secondary())
        } else if store.state.authMethod == .yubiKey {
            AsyncButton(Localizations.tryAgain) {
                await store.perform(.tryAgainTapped)
            }
            .buttonStyle(.secondary())
        }
    }

    /// The verification code text field.
    private var verificationCodeTextField: some View {
        BitwardenTextField(
            title: Localizations.verificationCode,
            text: store.binding(
                get: \.verificationCode,
                send: TwoFactorAuthAction.verificationCodeChanged
            )
        )
        .textFieldConfiguration(verificationTextFieldConfiguration)
    }
}

// MARK: - Previews

#Preview {
    TwoFactorAuthView(store: Store(processor: StateProcessor(
        state: TwoFactorAuthState()
    ))).navStackWrapped
}

#Preview("Duo") {
    TwoFactorAuthView(store: Store(processor: StateProcessor(
        state: TwoFactorAuthState(authMethod: .duo)
    ))).navStackWrapped
}

#Preview("WebAuthn") {
    TwoFactorAuthView(store: Store(processor: StateProcessor(
        state: TwoFactorAuthState(authMethod: .webAuthn)
    ))).navStackWrapped
}
