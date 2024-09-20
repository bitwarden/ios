import SwiftUI

// MARK: - RemoveMasterPasswordView

/// A view that notifies the user that they need to remove their master password.
///
struct RemoveMasterPasswordView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<RemoveMasterPasswordState, RemoveMasterPasswordAction, RemoveMasterPasswordEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 24) {
            Text(Localizations.removeMasterPasswordMessage(store.state.organizationName))
                .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                .styleGuide(.body)

            BitwardenTextField(
                title: Localizations.masterPassword,
                text: store.binding(
                    get: \.masterPassword,
                    send: RemoveMasterPasswordAction.masterPasswordChanged
                ),
                footer: nil,
                accessibilityIdentifier: "MasterPasswordEntry",
                passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
                isPasswordAutoFocused: true,
                isPasswordVisible: store.binding(
                    get: \.isMasterPasswordRevealed,
                    send: RemoveMasterPasswordAction.revealMasterPasswordFieldPressed
                )
            )
            .textFieldConfiguration(.password)
            .submitLabel(.go)
            .onSubmit {
                Task {
                    await store.perform(.continueFlow)
                }
            }

            AsyncButton(Localizations.continue) {
                await store.perform(.continueFlow)
            }
            .buttonStyle(.primary())
        }
        .navigationBar(title: Localizations.removeMasterPassword, titleDisplayMode: .inline)
        .scrollView()
    }
}

// MARK: - Previews

#if DEBUG
#Preview("RemoveMasterPassword") {
    RemoveMasterPasswordView(
        store: Store(
            processor: StateProcessor(
                state: RemoveMasterPasswordState(
                    masterPassword: "password",
                    organizationName: "Example Org"
                )
            )
        )
    )
}
#endif
