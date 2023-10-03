import SwiftUI

// MARK: - CreateAccountView

/// A view that allows the user to create an account.
///
struct CreateAccountView: View {
    // MARK: Properties

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
        ScrollView(showsIndicators: false) {
            VStack {
                emailAndPassword

                PasswordStrengthIndicator(minimumPasswordLength: Constants.minimumPasswordCharacters)

                VStack(spacing: 16) {
                    retypePassword

                    passwordHint
                }

                VStack(spacing: 24) {
                    toggles

                    submitButton
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 12)
            .padding([.top, .bottom], 16)
        }
        .background(Color(asset: Asset.Colors.backgroundSecondary))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Localizations.createAccount)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    store.send(.dismiss)
                } label: {
                    Image(asset: Asset.Images.cancel)
                        .resizable()
                        .foregroundColor(Color(asset: Asset.Colors.primaryBitwarden))
                        .frame(width: 24, height: 24)
                }
            }
        }
    }

    // MARK: Private views

    /// A toggle to check the user's password for security breaches.
    private var checkBreachesToggle: some View {
        HStack {
            Text(Localizations.checkKnownDataBreachesForThisPassword)
                .foregroundColor(Color(asset: Asset.Colors.textPrimary))
                .font(.system(.footnote))

            Spacer()

            Toggle(isOn: store.binding(
                get: \.isCheckDataBreachesToggleOn,
                send: CreateAccountAction.toggleCheckDataBreaches
            )) {}
                .tint(Color(asset: Asset.Colors.primaryBitwarden))
                .labelsHidden()
                .id(ViewIdentifier.CreateAccount.checkBreaches)
        }
    }

    /// The text fields for the user's email and password.
    private var emailAndPassword: some View {
        VStack(spacing: 16) {
            BitwardenTextField(
                title: Localizations.emailAddress,
                contentType: .emailAddress,
                autoCapitalizationType: .never,
                keyboardType: .emailAddress,
                text: store.binding(
                    get: \.emailText,
                    send: CreateAccountAction.emailTextChanged
                )
            )

            BitwardenTextField(
                title: Localizations.masterPassword,
                contentType: .password,
                autoCapitalizationType: .never,
                isPasswordVisible: store.binding(
                    get: \.arePasswordsVisible,
                    send: CreateAccountAction.togglePasswordVisibility
                ),
                text: store.binding(
                    get: \.passwordText,
                    send: CreateAccountAction.passwordTextChanged
                )
            )
        }
    }

    /// The master password hint.
    private var passwordHint: some View {
        VStack(alignment: .leading) {
            BitwardenTextField(
                title: Localizations.masterPasswordHint,
                contentType: .name,
                text: store.binding(
                    get: \.passwordHintText,
                    send: CreateAccountAction.passwordHintTextChanged
                )
            )

            Text(Localizations.masterPasswordHintDescription)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                .font(.system(.footnote))
        }
    }

    /// The text field for re-typing the master password.
    private var retypePassword: some View {
        BitwardenTextField(
            title: Localizations.retypeMasterPassword,
            contentType: .password,
            autoCapitalizationType: .never,
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CreateAccountAction.togglePasswordVisibility
            ),
            text: store.binding(
                get: \.retypePasswordText,
                send: CreateAccountAction.retypePasswordTextChanged
            )
        )
    }

    /// The button pressed when the user attempts to create the account.
    private var submitButton: some View {
        Button {
            Task {
                // TODO: BIT-104
            }
        } label: {
            Text(Localizations.submit)
        }
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
        HStack {
            Text("\(Localizations.acceptPolicies)\n")
                .foregroundColor(Color(asset: Asset.Colors.textPrimary))
                .font(.system(.footnote)) +
            Text("\(termsOfServiceString ?? "") \(privacyPolicyString ?? "")")
                .font(.system(.footnote))

            Spacer()

            Toggle(isOn: store.binding(
                get: \.isTermsAndPrivacyToggleOn,
                send: CreateAccountAction.toggleTermsAndPrivacy
            )) {}
                .tint(Color(asset: Asset.Colors.primaryBitwarden))
                .labelsHidden()
                .id(ViewIdentifier.CreateAccount.termsAndPrivacy)
        }
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
