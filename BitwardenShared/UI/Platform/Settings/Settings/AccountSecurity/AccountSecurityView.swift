import SwiftUI

// MARK: - AccountSecurityView

/// A view that allows the user to update their account security settings.
///
struct AccountSecurityView: View {
    // MARK: Properties

    /// An action that opens URLs.
    @Environment(\.openURL) private var openURL

    /// The store used to render the view.
    @ObservedObject var store: Store<AccountSecurityState, AccountSecurityAction, AccountSecurityEffect>

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            setUpUnlockActionCard

            pendingLoginRequests

            if store.state.showUnlockOptions {
                unlockOptionsSection
            }

            authenticatorSyncSection

            sessionTimeoutSection

            otherSection
        }
        .animation(.easeInOut, value: store.state.badgeState?.vaultUnlockSetupProgress == .complete)
        .scrollView(padding: 12)
        .navigationBar(title: Localizations.accountSecurity, titleDisplayMode: .inline)
        .onChange(of: store.state.twoStepLoginUrl) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearTwoStepLoginUrl)
        }
        .onChange(of: store.state.fingerprintPhraseUrl) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearFingerprintPhraseUrl)
        }
        .task {
            await store.perform(.appeared)
        }
        .task {
            await store.perform(.loadData)
        }
        .task {
            await store.perform(.streamSettingsBadge)
        }
    }

    // MARK: Private views

    /// The action card for setting up vault unlock methods.
    @ViewBuilder private var setUpUnlockActionCard: some View {
        if let progress = store.state.badgeState?.vaultUnlockSetupProgress, progress != .complete {
            ActionCard(
                title: Localizations.setUpUnlock,
                actionButtonState: ActionCard.ButtonState(title: Localizations.getStarted) {
                    store.send(.showSetUpUnlock)
                },
                dismissButtonState: ActionCard.ButtonState(title: Localizations.dismiss) {
                    await store.perform(.dismissSetUpUnlockActionCard)
                }
            ) {
                BitwardenBadge(badgeValue: "1")
            }
        }
    }

    /// The other section.
    private var otherSection: some View {
        SectionView(Localizations.other) {
            ContentBlock(dividerLeadingPadding: 16) {
                SettingsListItem(
                    Localizations.accountFingerprintPhrase,
                    hasDivider: false,
                    accessibilityIdentifier: "AccountFingerprintPhraseLabel"
                ) {
                    Task {
                        await store.perform(.accountFingerprintPhrasePressed)
                    }
                }

                SettingsListItem(
                    Localizations.twoStepLogin,
                    hasDivider: false,
                    accessibilityIdentifier: "TwoStepLoginLinkItemView"
                ) {
                    store.send(.twoStepLoginPressed)
                } trailingContent: {
                    Image(asset: Asset.Images.externalLink24)
                        .imageStyle(.rowIcon)
                }

                if store.state.isLockNowVisible {
                    SettingsListItem(
                        Localizations.lockNow,
                        hasDivider: false,
                        accessibilityIdentifier: "LockNowLabel"
                    ) {
                        Task {
                            await store.perform(.lockVault)
                        }
                    }
                }

                SettingsListItem(
                    Localizations.logOut,
                    hasDivider: false,
                    accessibilityIdentifier: "LogOutLabel"
                ) {
                    store.send(.logout)
                }

                SettingsListItem(
                    Localizations.deleteAccount,
                    hasDivider: false,
                    accessibilityIdentifier: "DeleteAccountLabel"
                ) {
                    store.send(.deleteAccountPressed)
                }
            }
        }
    }

    /// The pending login requests section.
    private var pendingLoginRequests: some View {
        SectionView(Localizations.approveLoginRequests) {
            SettingsListItem(
                Localizations.pendingLogInRequests,
                hasDivider: false,
                accessibilityIdentifier: "PendingLogInRequestsLabel"
            ) {
                store.send(.pendingLoginRequestsTapped)
            } trailingContent: {
                Image(asset: Asset.Images.chevronRight16)
                    .imageStyle(.accessoryIcon16)
            }
            .contentBlock()
        }
    }

    /// The session timeout section.
    private var sessionTimeoutSection: some View {
        SectionView(Localizations.sessionTimeout, contentSpacing: 8) {
            VStack(spacing: 16) {
                if let policyTimeoutMessage = store.state.policyTimeoutMessage {
                    InfoContainer(policyTimeoutMessage)
                }

                ContentBlock(dividerLeadingPadding: 16) {
                    BitwardenMenuField(
                        title: Localizations.sessionTimeout,
                        accessibilityIdentifier: "VaultTimeoutChooser",
                        options: store.state.availableTimeoutOptions,
                        selection: store.binding(
                            get: \.sessionTimeoutValue,
                            send: AccountSecurityAction.sessionTimeoutValueChanged
                        )
                    )

                    if store.state.isShowingCustomTimeout {
                        SettingsPickerField(
                            title: Localizations.custom,
                            customTimeoutValue: store.state.customTimeoutString,
                            pickerValue: store.binding(
                                get: \.customTimeoutValueSeconds,
                                send: AccountSecurityAction.customTimeoutValueSecondsChanged
                            ),
                            hasDivider: false,
                            customTimeoutAccessibilityLabel: store.state.customTimeoutAccessibilityLabel
                        )
                    }

                    BitwardenMenuField(
                        title: Localizations.sessionTimeoutAction,
                        accessibilityIdentifier: "VaultTimeoutActionChooser",
                        options: store.state.availableTimeoutActions,
                        selection: store.binding(
                            get: \.sessionTimeoutAction,
                            send: AccountSecurityAction.sessionTimeoutActionChanged
                        )
                    )
                    .disabled(store.state.isSessionTimeoutActionDisabled)
                }
            }
        }
    }

    /// The unlock options section.
    private var unlockOptionsSection: some View {
        SectionView(Localizations.unlockOptions) {
            ContentBlock(dividerLeadingPadding: 16) {
                biometricsSetting

                if store.state.unlockWithPinFeatureAvailable {
                    BitwardenToggle(
                        Localizations.unlockWithPIN,
                        isOn: store.bindingAsync(
                            get: \.isUnlockWithPINCodeOn,
                            perform: AccountSecurityEffect.toggleUnlockWithPINCode
                        )
                    )
                    .accessibilityIdentifier("UnlockWithPinSwitch")
                }
            }
        }
    }

    /// The authenticator sync section.
    @ViewBuilder private var authenticatorSyncSection: some View {
        if store.state.shouldShowAuthenticatorSyncSection {
            SectionView(Localizations.authenticatorSync) {
                BitwardenToggle(
                    Localizations.allowAuthenticatorSyncing,
                    isOn: store.bindingAsync(
                        get: \.isAuthenticatorSyncEnabled,
                        perform: AccountSecurityEffect.toggleSyncWithAuthenticator
                    ),
                    accessibilityIdentifier: Localizations.allowAuthenticatorSyncing
                )
                .contentBlock()
            }
        }
    }

    /// A view for the user's biometrics setting
    ///
    @ViewBuilder private var biometricsSetting: some View {
        switch store.state.biometricUnlockStatus {
        case let .available(type, enabled: enabled):
            biometricUnlockToggle(enabled: enabled, type: type)
        default:
            EmptyView()
        }
    }

    /// A toggle for the user's biometric unlock preference.
    ///
    @ViewBuilder
    private func biometricUnlockToggle(enabled: Bool, type: BiometricAuthenticationType) -> some View {
        let toggleText = biometricsToggleText(type)
        BitwardenToggle(
            toggleText,
            isOn: store.bindingAsync(
                get: { _ in enabled },
                perform: AccountSecurityEffect.toggleUnlockWithBiometrics
            )
        )
        .accessibilityIdentifier("UnlockWithBiometricsSwitch")
        .accessibilityLabel(toggleText)
    }

    private func biometricsToggleText(_ biometryType: BiometricAuthenticationType) -> String {
        switch biometryType {
        case .faceID:
            return Localizations.unlockWith(Localizations.faceID)
        case .opticID:
            return Localizations.unlockWith(Localizations.opticID)
        case .touchID:
            return Localizations.unlockWith(Localizations.touchID)
        case .unknown:
            return Localizations.unlockWithUnknownBiometrics
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        AccountSecurityView(
            store: Store(processor: StateProcessor(state: AccountSecurityState()))
        )
    }
}

#Preview("Vault Unlock Action Card") {
    NavigationView {
        AccountSecurityView(store: Store(processor: StateProcessor(state: AccountSecurityState(
            badgeState: .fixture(vaultUnlockSetupProgress: .setUpLater)
        ))))
    }
}
#endif
