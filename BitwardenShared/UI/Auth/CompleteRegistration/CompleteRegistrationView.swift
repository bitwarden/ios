import SwiftUI

// MARK: - CompleteRegistrationView

/// A view that allows the user to create an account.
///
struct CompleteRegistrationView: View {
    // MARK: Properties

    /// The store used to render the view.
    @ObservedObject var store: Store<
        CompleteRegistrationState,
        CompleteRegistrationAction,
        CompleteRegistrationEffect
    >

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            if store.state.nativeCreateAccountFeatureFlag {
                PageHeaderView(
                    image: Asset.Images.createAccountPassword,
                    title: Localizations.chooseYourMasterPassword,
                    message: Localizations.chooseAUniqueAndStrongPasswordToKeepYourInformationSafe
                )

                learnMoreSection
                    .padding(.vertical, 16)

                passwordField

                passwordStrengthIndicator
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(LocalizedStringKey(store.state.headelineTextBoldEmail))
                        .tint(Asset.Colors.textPrimary.swiftUIColor)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                        .multilineTextAlignment(.leading)
                        .styleGuide(.callout)
                        .padding(.bottom, 16)

                    passwordField
                        .padding(.bottom, 8)

                    passwordStrengthIndicator
                }
            }

            retypePassword

            passwordHint

            VStack(spacing: 24) {
                checkBreachesToggle
                    .padding(.top, 8)

                createAccountButton
            }
        }
        .animation(.default, value: store.state.passwordStrengthScore)
        .navigationBar(
            title: store.state.nativeCreateAccountFeatureFlag ?
                Localizations.createAccount :
                Localizations.setPassword,
            titleDisplayMode: .inline
        )
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

    /// The section where the user can learn more about passwords.
    private var learnMoreSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(decorative: Asset.Images.questionRound)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(Localizations.whatMakesAPasswordStrong)
                    .styleGuide(.body, weight: .semibold)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)

                Button {
                    store.send(.learnMoreTapped)
                } label: {
                    Text(Localizations.learnMore)
                        .styleGuide(.subheadline)
                        .foregroundStyle(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Asset.Colors.backgroundTertiary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// The text fields for the user's email and password.
    private var passwordField: some View {
        BitwardenTextField(
            title: store.state.nativeCreateAccountFeatureFlag
                ? Localizations.masterPasswordRequired
                : Localizations.masterPassword,
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

    /// The master password hint.
    private var passwordHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            BitwardenTextField(
                title: Localizations.masterPasswordHint,
                text: store.binding(
                    get: \.passwordHintText,
                    send: CompleteRegistrationAction.passwordHintTextChanged
                ),
                accessibilityIdentifier: "MasterPasswordHintLabel"
            )

            if store.state.nativeCreateAccountFeatureFlag {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
                        .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                        .styleGuide(.footnote)

                    Button {
                        store.send(.preventAccountLockTapped)
                    } label: {
                        Text(Localizations.learnAboutWaysToPreventAccountLockout)
                            .foregroundColor(Color(asset: Asset.Colors.primaryBitwardenLight))
                            .styleGuide(.footnote, weight: .bold)
                            .multilineTextAlignment(.leading)
                    }
                }
            } else {
                Text(Localizations.masterPasswordHintDescription)
                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                    .styleGuide(.footnote)
            }
        }
    }

    /// The password strength indicator.
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.state.nativeCreateAccountFeatureFlag {
                PasswordStrengthIndicator(
                    passwordStrengthScore: store.state.passwordStrengthScore,
                    passwordTextCount: store.state.passwordText.count,
                    requiredTextCount: store.state.requiredPasswordCount,
                    nativeCreateAccountFlow: store.state.nativeCreateAccountFeatureFlag
                )
            } else {
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
    }

    /// The text field for re-typing the master password.
    private var retypePassword: some View {
        BitwardenTextField(
            title: store.state.nativeCreateAccountFeatureFlag ?
                Localizations.retypeMasterPasswordRequired :
                Localizations.retypeMasterPassword,
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
            if store.state.nativeCreateAccountFeatureFlag {
                Text(Localizations.continue)
            } else {
                Text(Localizations.createAccount)
            }
        }
        .accessibilityIdentifier("CreateAccountButton")
        .buttonStyle(.primary())
        .disabled(!store.state.continueButtonEnabled)
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    CompleteRegistrationView(store: Store(processor: StateProcessor(
        state: CompleteRegistrationState(
            emailVerificationToken: "emailVerificationToken",
            nativeCreateAccountFeatureFlag: true,
            userEmail: "example@bitwarden.com"
        ))))
}
#endif
