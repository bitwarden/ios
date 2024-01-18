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

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            detailText

            verificationCodeTextField

            rememberMeToggle

            continueButton

            resendEmailButton
        }
        .scrollView()
        .navigationBar(title: store.state.authMethod.title, titleDisplayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                authMethodsMenu

                ToolbarButton(asset: Asset.Images.cancel, label: Localizations.close) {
                    store.send(.dismiss)
                }
            }
        }
        .toast(store.binding(
            get: \.toast,
            send: TwoFactorAuthAction.toastShown
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
    }

    // MARK: Private Views

    /// The two-factor authentication menu buttons.
    private var authMethodsMenu: some View {
        Menu {
            Menu(Localizations.useAnotherTwoStepMethod) {
                ForEach(store.state.availableAuthMethods) { method in
                    Button(method.title) {
                        store.send(.authMethodSelected(method))
                    }
                }
            }
        } label: {
            Image(asset: Asset.Images.verticalKabob, label: Text(Localizations.options))
                .resizable()
                .frame(width: 19, height: 19)
                .foregroundColor(Asset.Colors.primaryBitwarden.swiftUIColor)
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

    /// The detailed instructions for the method.
    private var detailText: some View {
        Text(store.state.detailsText)
            .styleGuide(.body)
            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.center)
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
            Button(Localizations.sendVerificationCodeAgain) {
                store.send(.resendEmailTapped)
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
        .textContentType(.oneTimeCode)
        .keyboardType(.numberPad)
    }
}

// MARK: - Previews

#Preview {
    TwoFactorAuthView(store: Store(processor: StateProcessor(state: TwoFactorAuthState())))
}
