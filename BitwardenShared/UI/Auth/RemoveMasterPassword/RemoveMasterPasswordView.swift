import BitwardenResources
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
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Localizations.removeMasterPasswordConfirmDomain)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.body)
                Text(Localizations.keyConnectorOrganization)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.body)
                Text(store.state.organizationName)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.body)
                Text(Localizations.keyConnectorDomain)
                    .foregroundColor(SharedAsset.Colors.textPrimary.swiftUIColor)
                    .styleGuide(.body)
                Text(store.state.keyConnectorUrl)
                    .foregroundColor(SharedAsset.Colors.textSecondary.swiftUIColor)
                    .styleGuide(.body)
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)

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
