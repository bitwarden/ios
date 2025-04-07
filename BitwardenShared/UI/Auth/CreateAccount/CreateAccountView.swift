import BitwardenKit
import SwiftUI

// MARK: - CreateAccountView

/// A view that allows the user to create an account.
///
struct CreateAccountView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<CreateAccountState, CreateAccountAction, CreateAccountEffect>

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
            VStack(spacing: 0) {
                emailAndPassword
                    .padding(.bottom, 8)

                passwordStrengthIndicator
            }

            retypePassword

            passwordHint

            VStack(spacing: 24) {
                toggles

                submitButton
            }
        }
        .animation(.default, value: store.state.passwordStrengthScore)
        .navigationBar(title: Localizations.createAccount, titleDisplayMode: .inline)
        .scrollView()
        .toolbar {
            cancelToolbarItem {
                store.send(.dismiss)
            }
        }
    }

    // MARK: Private views

    /// A toggle to check the user's password for security breaches.
    private var checkBreachesToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isCheckDataBreachesToggleOn,
            send: CreateAccountAction.toggleCheckDataBreaches
        )) {
            Text(Localizations.checkKnownDataBreachesForThisPassword)
                .styleGuide(.footnote)
        }
        .accessibilityIdentifier("CheckExposedMasterPasswordToggle")
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.CreateAccount.checkBreaches)
    }

    /// The text fields for the user's email and password.
    private var emailAndPassword: some View {
        VStack(spacing: 16) {
            BitwardenTextField(
                title: Localizations.emailAddress,
                text: store.binding(
                    get: \.emailText,
                    send: CreateAccountAction.emailTextChanged
                ),
                accessibilityIdentifier: "CreateAccountEmailAddressEntry"
            )
            .textFieldConfiguration(.email)

            BitwardenTextField(
                title: Localizations.masterPassword,
                text: store.binding(
                    get: \.passwordText,
                    send: CreateAccountAction.passwordTextChanged
                ),
                accessibilityIdentifier: "MasterPasswordEntry",
                passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.arePasswordsVisible,
                    send: CreateAccountAction.togglePasswordVisibility
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
                    send: CreateAccountAction.passwordHintTextChanged
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
                send: CreateAccountAction.retypePasswordTextChanged
            ),
            accessibilityIdentifier: "ConfirmMasterPasswordEntry",
            passwordVisibilityAccessibilityId: "ConfirmPasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CreateAccountAction.togglePasswordVisibility
            )
        )
        .textFieldConfiguration(.password)
    }

    /// The button pressed when the user attempts to create the account.
    private var submitButton: some View {
        Button {
            Task {
                await store.perform(.createAccount)
            }
        } label: {
            Text(Localizations.submit)
        }
        .accessibilityIdentifier("SubmitButton")
        .buttonStyle(.primary())
    }

    /// Toggles for checking data breaches and agreeing to the terms of service & privacy policy.
    private var toggles: some View {
        VStack(spacing: 24) {
            checkBreachesToggle
            termsAndPrivacyToggle
        }
        .padding(.top, 8)
    }

    /// A toggle for the terms and privacy agreement.
    private var termsAndPrivacyToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isTermsAndPrivacyToggleOn,
            send: CreateAccountAction.toggleTermsAndPrivacy
        )) {
            Text("\(Localizations.acceptPolicies)\n\(termsOfServiceString ?? "") \(privacyPolicyString ?? "")")
                .styleGuide(.footnote)
        }
        .accessibilityAction(named: Localizations.termsOfService) {
            openURL(ExternalLinksConstants.termsOfService)
        }
        .accessibilityAction(named: Localizations.privacyPolicy) {
            openURL(ExternalLinksConstants.privacyPolicy)
        }
        .accessibilityIdentifier("AcceptPoliciesToggle")
        .foregroundColor(Color(asset: Asset.Colors.textPrimary))
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.CreateAccount.termsAndPrivacy)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    CreateAccountView(store: Store(processor: StateProcessor(state: CreateAccountState())))
}
#endif
