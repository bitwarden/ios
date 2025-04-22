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
            VStack(alignment: .leading, spacing: 2) {
                Text(Localizations.removeMasterPasswordConfirmDomain)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .styleGuide(.body)

                Text(Localizations.keyConnectorOrganization)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .styleGuide(.body)

                Text(store.state.organizationName)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .styleGuide(.body)

                Text(Localizations.keyConnectorDomain)
                    .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .styleGuide(.body)

                Text(store.state.keyConnectorUrl)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .styleGuide(.body)
            }

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

            AsyncButton(Localizations.leaveOrganization) {
                await store.perform(.leaveOrganizationFlow)
            }
            .buttonStyle(.secondary())
        }
        .navigationBar(title: Localizations.removeMasterPassword, titleDisplayMode: .inline)
        .padding(.top, 12)
        .scrollView(padding: 12)
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
                    organizationName: "Example Org",
                    organizationId: "Mock-Id",
                    keyConnectorUrl: "www.example.com"
                )
            )
        )
    )
    .navStackWrapped
}
#endif
