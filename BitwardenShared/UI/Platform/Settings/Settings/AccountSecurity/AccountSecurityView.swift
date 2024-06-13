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
        VStack(spacing: 20) {
            pendingLoginRequests

            unlockOptionsSection

            sessionTimeoutSection

            otherSection
        }
        .scrollView()
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
    }

    // MARK: Private views

    /// The other section.
    private var otherSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.other)

            VStack(spacing: 0) {
                SettingsListItem(
                    Localizations.accountFingerprintPhrase,
                    accessibilityIdentifier: "AccountFingerprintPhraseLabel"
                ) {
                    Task {
                        await store.perform(.accountFingerprintPhrasePressed)
                    }
                }

                SettingsListItem(
                    Localizations.twoStepLogin,
                    accessibilityIdentifier: "TwoStepLoginLinkItemView"
                ) {
                    store.send(.twoStepLoginPressed)
                } trailingContent: {
                    Image(asset: Asset.Images.externalLink2)
                        .imageStyle(.rowIcon)
                }

                if store.state.isLockNowVisible {
                    SettingsListItem(
                        Localizations.lockNow,
                        accessibilityIdentifier: "LockNowLabel"
                    ) {
                        Task {
                            await store.perform(.lockVault)
                        }
                    }
                }

                SettingsListItem(
                    Localizations.logOut,
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
            .cornerRadius(10)
        }
    }

    /// The pending login requests section.
    private var pendingLoginRequests: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.approveLoginRequests)

            SettingsListItem(
                Localizations.pendingLogInRequests,
                hasDivider: false,
                accessibilityIdentifier: "PendingLogInRequestsLabel"
            ) {
                store.send(.pendingLoginRequestsTapped)
            }
            .cornerRadius(10)
        }
    }

    /// The session timeout section.
    private var sessionTimeoutSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.sessionTimeout)

            VStack(spacing: 0) {
                if let policyTimeoutMessage = store.state.policyTimeoutMessage {
                    InfoContainer(policyTimeoutMessage)
                        .padding(16)
                }

                SettingsMenuField(
                    title: Localizations.sessionTimeout,
                    options: store.state.availableTimeoutOptions,
                    accessibilityIdentifier: "VaultTimeoutChooser",
                    selectionAccessibilityID: "SessionTimeoutStatusLabel",
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
                        customTimeoutAccessibilityLabel: store.state.customTimeoutAccessibilityLabel
                    )
                }

                SettingsMenuField(
                    title: Localizations.sessionTimeoutAction,
                    options: store.state.availableTimeoutActions,
                    hasDivider: false,
                    accessibilityIdentifier: "VaultTimeoutActionChooser",
                    selectionAccessibilityID: "SessionTimeoutActionStatusLabel",
                    selection: store.binding(
                        get: \.sessionTimeoutAction,
                        send: AccountSecurityAction.sessionTimeoutActionChanged
                    )
                )
                .disabled(store.state.isSessionTimeoutActionDisabled)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.top, 8)
    }

    /// The unlock options section.
    private var unlockOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(Localizations.unlockOptions)

            VStack(spacing: 24) {
                biometricsSetting

                Toggle(isOn: store.binding(
                    get: \.isUnlockWithPINCodeOn,
                    send: AccountSecurityAction.toggleUnlockWithPINCode
                )) {
                    Text(Localizations.unlockWithPIN)
                }
                .toggleStyle(.bitwarden)
                .accessibilityIdentifier("UnlockWithPinSwitch")
            }
        }
    }

    /// A view for the user's biometrics setting
    ///
    @ViewBuilder private var biometricsSetting: some View {
        switch store.state.biometricUnlockStatus {
        case let .available(type, enabled: enabled, _):
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
        Toggle(isOn: store.bindingAsync(
            get: { _ in enabled },
            perform: AccountSecurityEffect.toggleUnlockWithBiometrics
        )) {
            Text(toggleText)
        }
        .accessibilityIdentifier("UnlockWithBiometricsSwitch")
        .accessibilityLabel(toggleText)
        .toggleStyle(.bitwarden)
    }

    private func biometricsToggleText(_ biometryType: BiometricAuthenticationType) -> String {
        switch biometryType {
        case .faceID:
            return Localizations.unlockWith(Localizations.faceID)
        case .touchID:
            return Localizations.unlockWith(Localizations.touchID)
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
#endif
