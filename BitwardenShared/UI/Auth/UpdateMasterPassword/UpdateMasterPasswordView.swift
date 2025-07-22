import BitwardenResources
import SwiftUI

// MARK: - UpdateMasterPasswordView

/// A view that forces the user to update their master password.
///
struct UpdateMasterPasswordView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<UpdateMasterPasswordState, UpdateMasterPasswordAction, UpdateMasterPasswordEffect>

    var body: some View {
        VStack(spacing: 24) {
            if store.state.forcePasswordResetReason != nil {
                InfoContainer(store.state.updateMasterPasswordWarning)

                if let policy = store.state.masterPasswordPolicy,
                   policy.isInEffect,
                   let policySummary = policy.policySummary {
                    InfoContainer(policySummary)
                }
            }

            ContentBlock {
                if store.state.requireCurrentPassword {
                    BitwardenTextField(
                        title: Localizations.currentMasterPasswordRequired,
                        text: store.binding(
                            get: \.currentMasterPassword,
                            send: UpdateMasterPasswordAction.currentMasterPasswordChanged
                        ),
                        accessibilityIdentifier: "MasterPasswordField",
                        passwordVisibilityAccessibilityId: "MasterPasswordVisibilityToggle",
                        isPasswordVisible: store.binding(
                            get: \.isCurrentMasterPasswordRevealed,
                            send: UpdateMasterPasswordAction.revealCurrentMasterPasswordFieldPressed
                        )
                    )
                    .textFieldConfiguration(.password)
                }

                BitwardenTextField(
                    title: Localizations.newMasterPasswordRequired,
                    text: store.binding(
                        get: \.masterPassword,
                        send: UpdateMasterPasswordAction.masterPasswordChanged
                    ),
                    accessibilityIdentifier: "NewPasswordField",
                    passwordVisibilityAccessibilityId: "NewPasswordVisibilityToggle",
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRevealed,
                        send: UpdateMasterPasswordAction.revealMasterPasswordFieldPressed
                    ),
                    footerContent: {
                        PasswordStrengthIndicator(
                            passwordStrengthScore: store.state.passwordStrengthScore,
                            passwordTextCount: store.state.masterPassword.count,
                            requiredTextCount: store.state.requiredPasswordCount
                        )
                        .padding(.vertical, 12)
                    }
                )
                .textFieldConfiguration(.password)

                BitwardenTextField(
                    title: Localizations.retypeNewMasterPasswordRequired,
                    text: store.binding(
                        get: \.masterPasswordRetype,
                        send: UpdateMasterPasswordAction.masterPasswordRetypeChanged
                    ),
                    accessibilityIdentifier: "RetypePasswordField",
                    passwordVisibilityAccessibilityId: "RetypePasswordVisibilityToggle",
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRetypeRevealed,
                        send: UpdateMasterPasswordAction.revealMasterPasswordRetypeFieldPressed
                    )
                )
                .textFieldConfiguration(.password)

                BitwardenTextField(
                    title: Localizations.newMasterPasswordHint,
                    text: store.binding(
                        get: \.masterPasswordHint,
                        send: UpdateMasterPasswordAction.masterPasswordHintChanged
                    ),
                    accessibilityIdentifier: "MasterPasswordHintLabel",
                    footerContent: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Localizations.bitwardenCannotResetALostOrForgottenMasterPassword)
                                .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
                                .styleGuide(.footnote)

                            Button {
                                store.send(.preventAccountLockTapped)
                            } label: {
                                Text(Localizations.learnAboutWaysToPreventAccountLockout)
                            }
                            .buttonStyle(.bitwardenBorderless)
                            .accessibilityIdentifier("PreventAccountLockButton")
                        }
                        .padding(.vertical, 12)
                    }
                )
            }
        }
        .scrollView()
        .background(SharedAsset.Colors.backgroundPrimary.swiftUIColor)
        .navigationTitle(Localizations.updateMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                toolbarButton(Localizations.logOut) {
                    await store.perform(.logoutTapped)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                primaryActionToolbarButton(Localizations.save) {
                    await store.perform(.saveTapped)
                }
                .accessibilityIdentifier("SaveButton")
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
        UpdateMasterPasswordView(
            store: Store(
                processor: StateProcessor(
                    state: UpdateMasterPasswordState()
                )
            )
        )
    }
}
#endif
