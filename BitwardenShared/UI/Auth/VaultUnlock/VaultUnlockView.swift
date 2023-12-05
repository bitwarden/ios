import SwiftUI

/// A view that allows the user to enter their master password to unlock the vault or logout of the
/// current account.
///
struct VaultUnlockView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>

    /// The text to display in the footer of the master password text field.
    var footerText: String {
        """
        \(Localizations.vaultLockedMasterPassword)
        \(Localizations.loggedInAsOn(store.state.email, store.state.webVaultHost))
        """
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BitwardenTextField(
                    title: Localizations.masterPassword,
                    footer: footerText,
                    isPasswordVisible: store.binding(
                        get: \.isMasterPasswordRevealed,
                        send: VaultUnlockAction.revealMasterPasswordFieldPressed
                    ),
                    text: store.binding(
                        get: \.masterPassword,
                        send: VaultUnlockAction.masterPasswordChanged
                    )
                )
                .textFieldConfiguration(.password)

                Button {
                    Task { await store.perform(.unlockVault) }
                } label: {
                    Text(Localizations.unlock)
                }
                .buttonStyle(.primary(shouldFillWidth: true))
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.verifyMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarButton(asset: Asset.Images.verticalKabob, label: Localizations.options) {
                    store.send(.morePressed)
                }
            }
        }
    }
}

// MARK: - Previews

struct UnlockVaultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            email: "user@bitwarden.com",
                            webVaultHost: "vault.bitwarden.com"
                        )
                    )
                )
            )
        }
    }
}
