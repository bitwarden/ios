import SwiftUI

// MARK: - SetMasterPasswordView

/// A view that forces the user to set their master password.
///
struct SetMasterPasswordView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SetMasterPasswordState, SetMasterPasswordAction, SetMasterPasswordEffect>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(store.state.explanationText)
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.callout)
                    .multilineTextAlignment(.leading)

                if store.state.resetPasswordAutoEnroll {
                    InfoContainer(Localizations.resetPasswordAutoEnrollInviteWarning, textAlignment: .leading)
                }

                if let policy = store.state.masterPasswordPolicy,
                   policy.isInEffect,
                   let policySummary = policy.policySummary {
                    InfoContainer(policySummary, textAlignment: .leading)
                }

                BitwardenTextField(
                    title: Localizations.masterPassword,
                    text: store.binding(
                        get: \.masterPassword,
                        send: SetMasterPasswordAction.masterPasswordChanged
                    ),
                    footer: Localizations.masterPasswordDescription,
                    accessibilityIdentifier: "NewPasswordField",
                    passwordVisibilityAccessibilityId: "NewPasswordVisibilityToggle",
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRevealed,
                        send: SetMasterPasswordAction.revealMasterPasswordFieldPressed
                    )
                )
                .textFieldConfiguration(.password)

                BitwardenTextField(
                    title: Localizations.retypeMasterPassword,
                    text: store.binding(
                        get: \.masterPasswordRetype,
                        send: SetMasterPasswordAction.masterPasswordRetypeChanged
                    ),
                    accessibilityIdentifier: "RetypePasswordField",
                    passwordVisibilityAccessibilityId: "RetypePasswordVisibilityToggle",
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRevealed,
                        send: SetMasterPasswordAction.revealMasterPasswordFieldPressed
                    )
                )
                .textFieldConfiguration(.password)

                BitwardenTextField(
                    title: Localizations.masterPasswordHint,
                    text: store.binding(
                        get: \.masterPasswordHint,
                        send: SetMasterPasswordAction.masterPasswordHintChanged
                    ),
                    footer: Localizations.masterPasswordHintDescription,
                    accessibilityIdentifier: "MasterPasswordHintLabel"
                )

                AsyncButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .accessibilityIdentifier("SubmitButton")
                .buttonStyle(.primary())
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .navigationTitle(Localizations.setMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !store.state.isPrivilegeElevation {
                    cancelToolbarButton {
                        Task {
                            await store.perform(.cancelPressed)
                        }
                    }
                }
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }
}

// MARK: Previews

#if DEBUG
#Preview {
    NavigationView {
        SetMasterPasswordView(
            store: Store(
                processor: StateProcessor(
                    state: SetMasterPasswordState(organizationIdentifier: "")
                )
            )
        )
    }
}
#endif
