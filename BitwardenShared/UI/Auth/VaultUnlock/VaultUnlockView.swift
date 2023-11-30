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
        ZStack {
            scrollView
            profileSwitcher
        }
        .navigationTitle(Localizations.verifyMasterPassword)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ToolbarButton(asset: Asset.Images.verticalKabob, label: Localizations.options) {
                    store.send(.morePressed)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                profileSwitcherToolbarItem
            }
        }
        .task {
            await store.perform(.appeared)
        }
    }

    /// the scrollable content of the view.
    @ViewBuilder var scrollView: some View {
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
                .textContentType(.password)
                .textInputAutocapitalization(.never)

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
    }

    /// The Toolbar item for the profile switcher view.
    @ViewBuilder var profileSwitcherToolbarItem: some View {
        ProfileSwitcherToolbarView(
            store: store.child(
                state: { state in
                    state.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcherAction(action)
                },
                mapEffect: nil
            )
        )
    }

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { mainState in
                    mainState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcherAction(action)
                },
                mapEffect: { profileEffect in
                    .profileSwitcher(profileEffect)
                }
            )
        )
    }
}

// MARK: - Previews

#if DEBUG
struct UnlockVaultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            email: "user@bitwarden.com",
                            profileSwitcherState: .init(
                                accounts: [],
                                activeAccountId: nil,
                                isVisible: false
                            ),
                            webVaultHost: "vault.bitwarden.com"
                        )
                    )
                )
            )
        }

        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            email: "user@bitwarden.com",
                            profileSwitcherState: ProfileSwitcherState(
                                accounts: [
                                    ProfileSwitcherItem(
                                        email: "max.protecc@bitwarden.com",
                                        userId: "123",
                                        userInitials: "MP"
                                    ),
                                ],
                                activeAccountId: "123",
                                isVisible: false
                            ),
                            webVaultHost: "vault.bitwarden.com"
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profiles Closed")

        NavigationView {
            VaultUnlockView(
                store: Store(
                    processor: StateProcessor(
                        state: VaultUnlockState(
                            email: "user@bitwarden.com",
                            profileSwitcherState: ProfileSwitcherState(
                                accounts: [
                                    ProfileSwitcherItem(
                                        email: "max.protecc@bitwarden.com",
                                        userId: "123",
                                        userInitials: "MP"
                                    ),
                                ],
                                activeAccountId: "123",
                                isVisible: true
                            ),
                            webVaultHost: "vault.bitwarden.com"
                        )
                    )
                )
            )
        }
        .previewDisplayName("Profiles Open")
    }
}
#endif
