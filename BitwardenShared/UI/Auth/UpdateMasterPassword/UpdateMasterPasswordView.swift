import SwiftUI

// MARK: - UpdateMasterPasswordView

/// A view that force the user to update their master password.
///
struct UpdateMasterPasswordView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<UpdateMasterPasswordState, UpdateMasterPasswordAction, UpdateMasterPasswordEffect>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Localizations.updateMasterPasswordWarning)
                    .styleGuide(.callout)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .padding(16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Asset.Colors.primaryBitwarden.swiftUIColor, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text(Localizations.masterPasswordPolicyInEffect)
                    Text(" • \(Localizations.policyInEffectMinLength(20))")
                    Text(" • \(Localizations.policyInEffectUppercase)")
                }
                .styleGuide(.callout)
                .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                .padding(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Asset.Colors.primaryBitwarden.swiftUIColor, lineWidth: 1)
                }

                BitwardenTextField(
                    title: Localizations.currentMasterPassword,
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

                BitwardenTextField(
                    title: Localizations.masterPassword,
                    text: store.binding(
                        get: \.masterPassword,
                        send: UpdateMasterPasswordAction.masterPasswordChanged
                    ),
                    accessibilityIdentifier: "NewPasswordField",
                    passwordVisibilityAccessibilityId: "NewPasswordVisibilityToggle",
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRevealed,
                        send: UpdateMasterPasswordAction.revealMasterPasswordFieldPressed
                    )
                )
                .textFieldConfiguration(.password)

                BitwardenTextField(
                    title: Localizations.retypeMasterPassword,
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
                    title: Localizations.masterPasswordHint,
                    text: store.binding(
                        get: \.masterPasswordHint,
                        send: UpdateMasterPasswordAction.masterPasswordHintChanged
                    ),
                    footer: Localizations.masterPasswordHintDescription,
                    accessibilityIdentifier: "MasterPasswordHintLabel"
                )

                AsyncButton(Localizations.submit) {
                    await store.perform(.submitPressed)
                }
                .buttonStyle(.primary())
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor)
        .navigationTitle(Localizations.updateMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                AsyncButton(Localizations.logOut) {
                    await store.perform(.logoutPressed)
                }
            }
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
