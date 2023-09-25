import SwiftUI

// MARK: - CreateAccountView

/// A view that allows the user to create an account.
///
struct CreateAccountView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<CreateAccountState, CreateAccountAction, CreateAccountEffect>

    // MARK: View

    var body: some View {
        NavigationView {
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localizations.createAccount)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.dismiss)
                    } label: {
                        Image(asset: Asset.Images.cancel)
                            .resizable()
                            .foregroundColor(Color(asset: Asset.Colors.textPrimary))
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
    }

    // MARK: Private views

    /// A toggle to check the user's password for security breaches.
    private var checkBreachesToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isCheckDataBreachesToggleOn,
            send: CreateAccountAction.toggleCheckDataBreaches
        )) {}
            .toggleStyle(
                DescriptiveToggleStyle(description: {
                    Text(Localizations.checkKnownDataBreachesForThisPassword)
                        .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                        .font(.system(.footnote))
                })
            )
    }

    /// The text fields for the user's email and password.
    private var emailAndPassword: some View {
        VStack(spacing: 16) {
            BitwardenTextField(
                title: Localizations.emailAddress,
                contentType: .emailAddress,
                text: store.binding(
                    get: { $0.emailText },
                    send: { .emailTextChanged($0) }
                )
            )

            BitwardenTextField(
                title: Localizations.masterPassword,
                icon: store.state.passwordVisibleIcon,
                contentType: .password,
                isPasswordVisible: store.binding(
                    get: \.arePasswordsVisible,
                    send: CreateAccountAction.togglePasswordVisibility
                ),
                text: store.binding(
                    get: { $0.passwordText },
                    send: { .passwordTextChanged($0) }
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
                    get: { $0.passwordHintText },
                    send: { .passwordHintTextChanged($0) }
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
            icon: store.state.passwordVisibleIcon,
            contentType: .password,
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CreateAccountAction.togglePasswordVisibility
            ),
            text: store.binding(
                get: { $0.retypePasswordText },
                send: { .retypePasswordTextChanged($0) }
            )
        )
    }

    /// The button pressed when the user attempts to create the account.
    private var submitButton: some View {
        Button {
            Task {
                await store.perform(.createAccount)
            }
        } label: {
            Text(Localizations.submit)
                .bold()
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    /// A toggle for the terms and privacy agreement.
    private var termsAndPrivacyToggle: some View {
        Toggle(isOn: store.binding(
            get: \.isTermsAndPrivacyToggleOn,
            send: CreateAccountAction.toggleTermsAndPrivacy
        )) {}
            .toggleStyle(
                DescriptiveToggleStyle(
                    description: {
                        VStack(alignment: .leading) {
                            Text(Localizations.acceptPolicies)
                                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                                .font(.system(.footnote))

                            Text("Terms of Service, Privacy Policy")
                                .font(.system(.footnote))
                        }
                    }
                )
            )
    }

    /// Toggles for checking data breaches and agreeing to the terms of service & privacy policy.
    @ViewBuilder private var toggles: some View {
        checkBreachesToggle
        termsAndPrivacyToggle
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
