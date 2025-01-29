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
            VStack(spacing: 24) {
                PageHeaderView(
                    image: Asset.Images.Illustrations.lock,
                    title: Localizations.chooseYourMasterPassword,
                    message: store.state.explanationText
                )

                if store.state.resetPasswordAutoEnroll {
                    InfoContainer(Localizations.resetPasswordAutoEnrollInviteWarning)
                }

                if let policy = store.state.masterPasswordPolicy,
                   policy.isInEffect,
                   let policySummary = policy.policySummary {
                    InfoContainer(policySummary)
                }

                ContentBlock {
                    BitwardenTextField(
                        title: Localizations.masterPasswordRequired,
                        text: store.binding(
                            get: \.masterPassword,
                            send: SetMasterPasswordAction.masterPasswordChanged
                        ),
                        footer: Localizations.theMasterPasswordIsThePasswordYouUseToAccessYourVault,
                        accessibilityIdentifier: "NewPasswordField",
                        passwordVisibilityAccessibilityId: "NewPasswordVisibilityToggle",
                        isPasswordVisible: store.binding(
                            get: \.isMasterPasswordRevealed,
                            send: SetMasterPasswordAction.revealMasterPasswordFieldPressed
                        )
                    )
                    .textFieldConfiguration(.password)

                    BitwardenTextField(
                        title: Localizations.retypeMasterPasswordRequired,
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
                        accessibilityIdentifier: "MasterPasswordHintLabel",
                        footerContent: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
                                    .foregroundColor(Color(asset: Asset.Colors.textSecondary))
                                    .styleGuide(.footnote)

                                Button {
                                    store.send(.preventAccountLockTapped)
                                } label: {
                                    Text(Localizations.learnAboutWaysToPreventAccountLockout)
                                        .foregroundColor(Asset.Colors.textInteraction.swiftUIColor)
                                        .styleGuide(.footnote, weight: .bold)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    )
                }
                AsyncButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .accessibilityIdentifier("SubmitButton")
                .buttonStyle(.primary())
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
        .navigationTitle(Localizations.setMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
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
