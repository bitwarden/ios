import SwiftUI

/// A view that allows the user to enter their master password to unlock the vault or logout of the
/// current account.
///
struct VaultUnlockView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>

    /// The text to display in the footer of the password/pin text field.
    var footerText: String {
        """
        \(store.state.unlockMethod == .pin
            ? Localizations.vaultLockedPIN
            : Localizations.vaultLockedMasterPassword)
        \(Localizations.loggedInAsOn(store.state.email, store.state.webVaultHost))
        """
    }

    /// The view's navigation title.
    var navigationTitle: String {
        store.state.unlockMethod == .pin
            ? Localizations.verifyPIN
            : Localizations.verifyMasterPassword
    }

    var body: some View {
        ZStack {
            scrollView
            profileSwitcher
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if store.state.isInAppExtension {
                    cancelToolbarButton {
                        store.send(.cancelPressed)
                    }
                } else {
                    optionsToolbarMenu {
                        Button(Localizations.logOut) {
                            store.send(.morePressed)
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                profileSwitcherToolbarItem
            }
        }
        .task {
            await store.perform(.appeared)
        }
        .toast(store.binding(
            get: \.toast,
            send: VaultUnlockAction.toastShown
        ))
    }

    /// the scrollable content of the view.
    @ViewBuilder var scrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                textField

                biometricAuthButton

                AsyncButton {
                    await store.perform(.unlockVault)
                } label: {
                    Text(Localizations.unlock)
                }
                .buttonStyle(.primary(shouldFillWidth: true))
                .accessibilityIdentifier("UnlockVaultButton")
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
                    .profileSwitcher(action)
                },
                mapEffect: { effect in
                    .profileSwitcher(effect)
                }
            )
        )
    }

    /// A button to trigger a biometric auth unlock.
    @ViewBuilder private var biometricAuthButton: some View {
        if case let .available(biometryType, true, true) = store.state.biometricUnlockStatus {
            AsyncButton {
                Task { await store.perform(.unlockVaultWithBiometrics) }
            } label: {
                biometricUnlockText(biometryType)
            }
            .buttonStyle(.secondary(shouldFillWidth: true))
        }
    }

    /// A view that displays the ability to add or switch between account profiles
    @ViewBuilder private var profileSwitcher: some View {
        ProfileSwitcherView(
            store: store.child(
                state: { mainState in
                    mainState.profileSwitcherState
                },
                mapAction: { action in
                    .profileSwitcher(action)
                },
                mapEffect: { profileEffect in
                    .profileSwitcher(profileEffect)
                }
            )
        )
    }

    /// The text field for the pin or password.
    @ViewBuilder private var textField: some View {
        switch store.state.unlockMethod {
        case .password:
            BitwardenTextField(
                title: Localizations.masterPassword,
                text: store.binding(
                    get: \.masterPassword,
                    send: VaultUnlockAction.masterPasswordChanged
                ),
                footer: footerText,
                accessibilityIdentifier: "MasterPasswordEntry",
                passwordVisibilityAccessibilityId: "PasswordVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.isMasterPasswordRevealed,
                    send: VaultUnlockAction.revealMasterPasswordFieldPressed
                )
            )
            .textFieldConfiguration(.password)
            .submitLabel(.go)
            .onSubmit {
                Task {
                    await store.perform(.unlockVault)
                }
            }
        case .pin:
            BitwardenTextField(
                title: Localizations.pin,
                text: store.binding(
                    get: \.pin,
                    send: VaultUnlockAction.pinChanged
                ),
                footer: footerText,
                accessibilityIdentifier: "PinEntry",
                passwordVisibilityAccessibilityId: "PinVisibilityToggle",
                isPasswordVisible: store.binding(
                    get: \.isPinRevealed,
                    send: VaultUnlockAction.revealPinFieldPressed
                )
            )
            .textFieldConfiguration(.numeric(.password))
            .submitLabel(.go)
            .onSubmit {
                Task {
                    await store.perform(.unlockVault)
                }
            }
        }
    }

    private func biometricUnlockText(_ biometryType: BiometricAuthenticationType) -> some View {
        switch biometryType {
        case .faceID:
            Text(Localizations.useFaceIDToUnlock)
        case .touchID:
            Text(Localizations.useFingerprintToUnlock)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        VaultUnlockView(
            store: Store(
                processor: StateProcessor(
                    state: VaultUnlockState(
                        email: "user@bitwarden.com",
                        profileSwitcherState: .init(
                            accounts: [],
                            activeAccountId: nil,
                            allowLockAndLogout: true,
                            isVisible: false
                        ),
                        unlockMethod: .password,
                        webVaultHost: "vault.bitwarden.com"
                    )
                )
            )
        )
    }
}

#Preview {
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
                                    isUnlocked: false,
                                    userId: "123",
                                    userInitials: "MP",
                                    webVault: ""
                                ),
                            ],
                            activeAccountId: "123",
                            allowLockAndLogout: true,
                            isVisible: false
                        ),
                        unlockMethod: .pin,
                        webVaultHost: "vault.bitwarden.com"
                    )
                )
            )
        )
    }
    .previewDisplayName("Profiles Closed")
}

#Preview {
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
                                    isUnlocked: false,
                                    userId: "123",
                                    userInitials: "MP",
                                    webVault: ""
                                ),
                            ],
                            activeAccountId: "123",
                            allowLockAndLogout: true,
                            isVisible: true
                        ),
                        unlockMethod: .password,
                        webVaultHost: "vault.bitwarden.com"
                    )
                )
            )
        )
    }
    .previewDisplayName("Profiles Open")
}
#endif
