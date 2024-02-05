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
                    ToolbarButton(asset: Asset.Images.cancel, label: Localizations.cancel) {
                        store.send(.cancelPressed)
                    }
                } else {
                    ToolbarButton(asset: Asset.Images.verticalKabob, label: Localizations.options) {
                        store.send(.morePressed)
                    }
                    .accessibilityIdentifier(
                        "//XCUIElementTypeScrollView[2]/XCUIElementTypeOther[1]/XCUIElementTypeOther"
                    )
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
                    .profileSwitcherAction(action)
                },
                mapEffect: nil
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
                    .profileSwitcherAction(action)
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
            .textFieldConfiguration(.pin)
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
                            unlockMethod: .password,
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
                                        isUnlocked: false,
                                        userId: "123",
                                        userInitials: "MP"
                                    ),
                                ],
                                activeAccountId: "123",
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
                                        userInitials: "MP"
                                    ),
                                ],
                                activeAccountId: "123",
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
}
#endif
