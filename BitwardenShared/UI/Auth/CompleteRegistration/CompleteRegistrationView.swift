import SwiftUI

// MARK: - CompleteRegistrationView

/// A view that allows the user to create an account.
///
struct CompleteRegistrationView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<CompleteRegistrationState, CompleteRegistrationAction, CompleteRegistrationEffect>

    /// The privacy policy attributed string used in navigating to Bitwarden's Privacy Policy website.
    let privacyPolicyString: AttributedString? = try? AttributedString(
        markdown: "[\(Localizations.privacyPolicy)](\(ExternalLinksConstants.privacyPolicy))"
    )

    /// The terms of service attributed string used in navigating to Bitwarden's Terms of Service website.
    let termsOfServiceString: AttributedString? = try? AttributedString(
        markdown: "[\(Localizations.termsOfService),](\(ExternalLinksConstants.termsOfService))"
    )

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(.init(store.state.headelineTextBoldEmail))
                    .tint(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .styleGuide(.callout)
                    .padding(.bottom, 16)

                passwordField
                    .padding(.bottom, 8)

                passwordStrengthIndicator
            }

            retypePassword

            passwordHint

            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    checkBreachesToggle
                }
                .padding(.top, 8)

                createAccountButton
            }
        }
        .animation(.default, value: store.state.passwordStrengthScore)
        .navigationBar(title: Localizations.setPassword, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
        .task {
            await store.perform(.appeared)
        }
        .toast(store.binding(
            get: \.toast,
            send: CompleteRegistrationAction.toastShown
        ))
    }

    // MARK: Private views

    /// A toggle to check the user's password for security breaches.
    private var checkBreachesToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isCheckDataBreachesToggleOn,
            send: CompleteRegistrationAction.toggleCheckDataBreaches
        )) {
            Text(Localizations.checkKnownDataBreachesForThisPassword)
                .styleGuide(.footnote)
        }
        .accessibilityIdentifier("CheckExposedMasterPasswordToggle")
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.CompleteRegistration.checkBreaches)
    }

    /// The text fields for the user's email and password.
    private var passwordField: some View {
        VStack(spacing: 16) { BitwardenTextField(
            title: Localizations.masterPassword,
            text: store.binding(
                get: \.passwordText,
                send: CompleteRegistrationAction.passwordTextChanged
            ),
            accessibilityIdentifier: "MasterPasswordEntry",
            passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CompleteRegistrationAction.togglePasswordVisibility
            )
        )
        .textFieldConfiguration(.password)
        }
    }

    /// The master password hint.
    private var passwordHint: some View {
        VStack(alignment: .leading) {
            BitwardenTextField(
                title: Localizations.masterPasswordHint,
                text: store.binding(
                    get: \.passwordHintText,
                    send: CompleteRegistrationAction.passwordHintTextChanged
                ),
                accessibilityIdentifier: "MasterPasswordHintLabel"
            )

            Text(Localizations.masterPasswordHintDescription)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .styleGuide(.footnote)
        }
    }

    /// The password strength indicator.
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                Text(Localizations.important + ": ").bold() +
                    Text(Localizations.yourMasterPasswordCannotBeRecoveredIfYouForgetItXCharactersMinimum(
                        Constants.minimumPasswordCharacters)
                    )
            }
            .styleGuide(.footnote)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .padding(.bottom, 16)

            PasswordStrengthIndicator(
                passwordStrengthScore: store.state.passwordStrengthScore
            )
        }
    }

    /// The text field for re-typing the master password.
    private var retypePassword: some View {
        BitwardenTextField(
            title: Localizations.retypeMasterPassword,
            text: store.binding(
                get: \.retypePasswordText,
                send: CompleteRegistrationAction.retypePasswordTextChanged
            ),
            accessibilityIdentifier: "ConfirmMasterPasswordEntry",
            passwordVisibilityAccessibilityId: "ConfirmPasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CompleteRegistrationAction.togglePasswordVisibility
            )
        )
        .textFieldConfiguration(.password)
    }

    /// The button pressed when the user attempts to create the account.
    private var createAccountButton: some View {
        Button {
            Task {
                await store.perform(.completeRegistration)
            }
        } label: {
            Text(Localizations.createAccount)
        }
        .accessibilityIdentifier("CreateAccountButton")
        .buttonStyle(.primary())
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    CompleteRegistrationView(store: Store(processor: StateProcessor(
        state: CompleteRegistrationState(
            emailVerificationToken: "emailVerificationToken",
            userEmail: "example@bitwarden.com"
        ))))
}
#endif
