import BitwardenKit
import BitwardenResources
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
        VStack(spacing: 24) {
            IllustratedMessageView(
                image: Asset.Images.Illustrations.lock,
                title: Localizations.chooseYourMasterPassword,
                message: Localizations.chooseAUniqueAndStrongPasswordToKeepYourInformationSafe
            )
            .padding(.top, 12)

            learnMoreSection

            VStack(spacing: 8) {
                ContentBlock {
                    passwordField

                    retypePassword

                    passwordHint
                }

                checkBreachesToggle
            }

            createAccountButton
        }
        .animation(.default, value: store.state.passwordStrengthScore)
        .navigationBar(
            title: Localizations.createAccount,
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
        BitwardenToggle(isOn: store.binding(
            get: \.isCheckDataBreachesToggleOn,
            send: CompleteRegistrationAction.toggleCheckDataBreaches
        )) {
            Text(Localizations.checkKnownDataBreachesForThisPassword)
                .styleGuide(.footnote)
        }
        .accessibilityIdentifier("CheckExposedMasterPasswordToggle")
        .id(ViewIdentifier.CompleteRegistration.checkBreaches)
        .contentBlock()
    }

    /// The section where the user can learn more about passwords.
    private var learnMoreSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(decorative: Asset.Images.questionCircle24)
                .foregroundStyle(SharedAsset.Colors.iconSecondary.swiftUIColor)

            VStack(alignment: .leading, spacing: 0) {
                Text(Localizations.whatMakesAPasswordStrong)
                    .styleGuide(.body, weight: .semibold)
                    .foregroundStyle(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)

                Button {
                    store.send(.learnMoreTapped)
                } label: {
                    Text(Localizations.learnMore)
                        .styleGuide(.subheadline)
                        .foregroundStyle(SharedAsset.Colors.textInteraction.swiftUIColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(SharedAsset.Colors.backgroundSecondary.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// The text fields for the user's email and password.
    private var passwordField: some View {
        BitwardenTextField(
            title: Localizations.masterPasswordRequired,
            text: store.binding(
                get: \.passwordText,
                send: CompleteRegistrationAction.passwordTextChanged
            ),
            accessibilityIdentifier: "MasterPasswordEntry",
            passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
            isPasswordVisible: store.binding(
                get: \.arePasswordsVisible,
                send: CompleteRegistrationAction.togglePasswordVisibility
            ),
            footerContent: {
                passwordStrengthIndicator
                    .padding(.vertical, 12)
                    .padding(.trailing, 12)
            }
        )
        .textFieldConfiguration(.password)
    }

    /// The master password hint.
    private var passwordHint: some View {
        BitwardenTextField(
            title: Localizations.masterPasswordHint,
            text: store.binding(
                get: \.passwordHintText,
                send: CompleteRegistrationAction.passwordHintTextChanged
            ),
            accessibilityIdentifier: "MasterPasswordHintLabel",
            footerContent: {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
                        .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                        .styleGuide(.footnote)

                    Button {
                        store.send(.preventAccountLockTapped)
                    } label: {
                        Text(Localizations.learnAboutWaysToPreventAccountLockout)
                            .foregroundColor(SharedAsset.Colors.textInteraction.swiftUIColor)
                            .styleGuide(.footnote, weight: .bold)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.vertical, 12)
            }
        )
    }

    /// The password strength indicator.
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 0) {
            PasswordStrengthIndicator(
                passwordStrengthScore: store.state.passwordStrengthScore,
                passwordTextCount: store.state.passwordText.count,
                requiredTextCount: store.state.requiredPasswordCount
            )
        }
    }

    /// The text field for re-typing the master password.
    private var retypePassword: some View {
        BitwardenTextField(
            title: Localizations.retypeMasterPasswordRequired,
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
            Text(Localizations.continue)
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
            userEmail: "example@bitwarden.com"
        ))))
}
#endif
