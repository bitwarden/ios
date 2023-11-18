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

                PasswordStrengthIndicator(
                    minimumPasswordLength: Constants.minimumPasswordCharacters,
                    passwordStrengthScore: store.state.passwordStrengthScore
                )
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
                .font(.styleGuide(.footnote))
        }
        .accessibilityIdentifier("CheckExposedMasterPasswordToggle")
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.CreateAccount.checkBreaches)
    }

    /// The text fields for the user's email and password.
    private var emailAndPassword: some View {
        VStack(spacing: 16) {
            BitwardenTextField(
                accessibilityIdentifier: "EmailAddressEntry",
                title: Localizations.emailAddress,
                text: store.binding(
                    get: \.emailText,
                    send: CreateAccountAction.emailTextChanged
                )
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            BitwardenTextField(
                accessibilityIdentifier: "MasterPasswordEntry",
                title: Localizations.masterPassword,
                isPasswordVisible: store.binding(
                    get: \.arePasswordsVisible,
                    send: CreateAccountAction.togglePasswordVisibility
                ),
                passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
                text: store.binding(
                    get: \.passwordText,
                    send: CreateAccountAction.passwordTextChanged
                )
            )
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
    }

    /// The master password hint.
    private var passwordHint: some View {
        VStack(alignment: .leading) {
            BitwardenTextField(
                accessibilityIdentifier: "MasterPasswordHintLabel",
                title: Localizations.masterPasswordHint,
                text: store.binding(
                    get: \.passwordHintText,
                    send: CreateAccountAction.passwordHintTextChanged
                )
            )

            Text(Localizations.masterPasswordHintDescription)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.styleGuide(.footnote))
        }
    }

    /// The text field for re-typing the master password.
    private var retypePassword: some View {
        BitwardenTextField(
            accessibilityIdentifier: "ConfirmMasterPasswordEntry",
            title: Localizations.retypeMasterPassword,
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CreateAccountAction.togglePasswordVisibility
            ),
            passwordVisibilityAccessibilityId: "ConfirmPasswordVisibilityToggle",
            text: store.binding(
                get: \.retypePasswordText,
                send: CreateAccountAction.retypePasswordTextChanged
            )
        )
        .textContentType(.password)
        .textInputAutocapitalization(.never)
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
        .accessibilityIdentifier("CreateAccountLabel")
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
        }
        .accessibilityAction(named: Localizations.termsOfService) {
            openURL(ExternalLinksConstants.termsOfService)
        }
        .accessibilityAction(named: Localizations.privacyPolicy) {
            openURL(ExternalLinksConstants.privacyPolicy)
        }
        .accessibilityIdentifier("AcceptPoliciesToggle")
        .foregroundColor(Color(asset: Asset.Colors.textPrimary))
        .font(.styleGuide(.footnote))
        .toggleStyle(.bitwarden)
        .id(ViewIdentifier.CreateAccount.termsAndPrivacy)
    }
}

// MARK: Previews

#if DEBUG
struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView(store: Store(processor: StateProcessor(state: CreateAccountState())))
    }
}
#endif
