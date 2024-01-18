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
            approveLoginRequestsSection

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
            await store.perform(.loadData)
        }
    }

    // MARK: Private views

    /// The approve login requests section.
    private var approveLoginRequestsSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.approveLoginRequests)

            Toggle(isOn: store.binding(
                get: \.isApproveLoginRequestsToggleOn,
                send: AccountSecurityAction.toggleApproveLoginRequestsToggle
            )) {
                Text(Localizations.useThisDeviceToApproveLoginRequestsMadeFromOtherDevices)
            }
            .toggleStyle(.bitwarden)

            if store.state.isApproveLoginRequestsToggleOn {
                SettingsListItem(
                    Localizations.pendingLogInRequests,
                    hasDivider: false
                ) {}
                    .cornerRadius(10)
            }
        }
    }

    /// The other section.
    private var otherSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.other)

            VStack(spacing: 0) {
                SettingsListItem(Localizations.accountFingerprintPhrase) {
                    Task {
                        await store.perform(.accountFingerprintPhrasePressed)
                    }
                }

                SettingsListItem(Localizations.twoStepLogin) {
                    store.send(.twoStepLoginPressed)
                } trailingContent: {
                    Image(asset: Asset.Images.externalLink2)
                        .resizable()
                        .frame(width: 22, height: 22)
                }

                SettingsListItem(Localizations.lockNow) {
                    Task {
                        await store.perform(.lockVault)
                    }
                }

                SettingsListItem(Localizations.logOut) {
                    store.send(.logout)
                }

                SettingsListItem(
                    Localizations.deleteAccount,
                    hasDivider: false
                ) {
                    store.send(.deleteAccountPressed)
                }
            }
            .cornerRadius(10)
        }
    }

    /// The session timeout section.
    private var sessionTimeoutSection: some View {
        VStack(alignment: .leading) {
            SectionHeaderView(Localizations.sessionTimeout)

            VStack(spacing: 0) {
                SettingsMenuField(
                    title: Localizations.sessionTimeout,
                    options: SessionTimeoutValue.allCases,
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
                            get: \.customSessionTimeoutValue,
                            send: AccountSecurityAction.setCustomSessionTimeoutValue
                        ),
                        customTimeoutAccessibilityLabel: store.state.customTimeoutAccessibilityLabel
                    )
                }

                SettingsMenuField(
                    title: Localizations.sessionTimeoutAction,
                    options: SessionTimeoutAction.allCases,
                    hasDivider: false,
                    selection: store.binding(
                        get: \.sessionTimeoutAction,
                        send: AccountSecurityAction.sessionTimeoutActionChanged
                    )
                )
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
struct AccountSecurityView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountSecurityView(
                store: Store(processor: StateProcessor(state: AccountSecurityState()))
            )
        }
    }
}
#endif
