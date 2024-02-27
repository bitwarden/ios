import SwiftUI

// MARK: - TwoFactorAuthView

/// A view that prompts the user for a two-factor authentication code..
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
            .navigationBar(title: store.state.authMethod.title, titleDisplayMode: .inline)
            .task(id: store.state.authMethod) {
                guard store.state.authMethod == .yubiKey else { return }
                await store.perform(.listenForNFC)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    authMethodsMenu

                    cancelToolbarButton {
                        store.send(.dismiss)
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
        VStack(spacing: 16) {
            detailText

            verificationCodeTextField

            rememberMeToggle

            continueButton

            resendEmailButton
        }
        .scrollView()
    }

    /// The detailed instructions for the method.
    private var detailText: some View {
        VStack(spacing: 16) {
            Text(store.state.detailsText)
                .styleGuide(.body)
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .multilineTextAlignment(.center)

            if let detailImageAsset = store.state.detailImageAsset {
                Image(decorative: detailImageAsset)
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
        VStack(spacing: 16) {
            detailText

            rememberMeToggle

            duoButton
        }
        .scrollView()
        .toast(store.binding(
            get: \.toast,
            send: TwoFactorAuthAction.toastShown
        ))
    }

    /// The remember me toggle.
    private var rememberMeToggle: some View {
        Toggle(
            Localizations.rememberMe,
            isOn: store.binding(
                get: { $0.isRememberMeOn },
                send: { .rememberMeToggleChanged($0) }
            )
        )
        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        .toggleStyle(.bitwarden)
    }

    /// The resend email button for the email authentication option.
    @ViewBuilder private var resendEmailButton: some View {
        if store.state.authMethod == .email {
            AsyncButton(Localizations.sendVerificationCodeAgain) {
                await store.perform(.resendEmailTapped)
            }
            .buttonStyle(.tertiary())
        } else if store.state.authMethod == .yubiKey {
            AsyncButton(Localizations.tryAgain) {
                await store.perform(.tryAgainTapped)
            }
            .buttonStyle(.tertiary())
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
    TwoFactorAuthView(store: Store(processor: StateProcessor(state: TwoFactorAuthState())))
}
