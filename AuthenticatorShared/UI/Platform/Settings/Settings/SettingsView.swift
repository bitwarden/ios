import BitwardenKit
import BitwardenResources
import SwiftUI

// MARK: - SettingsView

/// A view containing the top-level list of settings.
///
struct SettingsView: View {
    // MARK: Properties

    /// An object used to open urls from this view.
    @Environment(\.openURL) private var openURL

    /// The `Store` for this view.
    @ObservedObject var store: Store<SettingsState, SettingsAction, SettingsEffect>

    // MARK: View

    var body: some View {
        settingsItems
            .scrollView()
            .navigationBar(title: Localizations.settings, titleDisplayMode: .large)
            .toast(store.binding(
                get: \.toast,
                send: SettingsAction.toastShown
            ))
            .onChange(of: store.state.url) { newValue in
                guard let url = newValue else { return }
                openURL(url)
                store.send(.clearURL)
            }
            .task {
                await store.perform(.loadData)
            }
    }

    // MARK: Private views

    /// A view for the user's biometrics setting
    ///
    @ViewBuilder private var biometricsSetting: some View {
        switch store.state.biometricUnlockStatus {
        case let .available(type, enabled: enabled, _):
            SectionView(Localizations.security) {
                VStack(spacing: 8) {
                    biometricUnlockToggle(enabled: enabled, type: type)
                    SettingsMenuField(
                        title: Localizations.sessionTimeout,
                        options: SessionTimeoutValue.allCases,
                        hasDivider: false,
                        accessibilityIdentifier: "VaultTimeoutChooser",
                        selectionAccessibilityID: "SessionTimeoutStatusLabel",
                        selection: store.bindingAsync(
                            get: \.sessionTimeoutValue,
                            perform: SettingsEffect.sessionTimeoutValueChanged
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.bottom, 32)
        default:
            EmptyView()
        }
    }

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.rightAngle)
            .resizable()
            .scaledFrame(width: 12, height: 12)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
    }

    /// The copyright notice.
    private var copyrightNotice: some View {
        Text(store.state.copyrightText)
            .styleGuide(.caption2)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The language picker view
    private var language: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsListItem(
                Localizations.language,
                hasDivider: false
            ) {
                store.send(.languageTapped)
            } trailingContent: {
                Text(store.state.currentLanguage.title)
            }
            .cornerRadius(10)

            Text(Localizations.languageChangeRequiresAppRestart)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
    }

    /// The settings items.
    private var settingsItems: some View {
        VStack(spacing: 0) {
            biometricsSetting

            SectionView(Localizations.data, contentSpacing: 0) {
                VStack(spacing: 0) {
                    SettingsListItem(Localizations.import) {
                        store.send(.importItemsTapped)
                    }

                    SettingsListItem(Localizations.export) {
                        store.send(.exportItemsTapped)
                    }

                    SettingsListItem(Localizations.backup) {
                        store.send(.backupTapped)
                    }

                    syncWithPasswordManagerRow(hasDivider: store.state.shouldShowDefaultSaveOption)

                    if store.state.shouldShowDefaultSaveOption {
                        defaultSaveOption
                    }
                }
                .cornerRadius(10)
            }
            .padding(.bottom, 32)

            SectionView(Localizations.appearance) {
                theme
            }
            .padding(.bottom, 32)

            SectionView(Localizations.help, contentSpacing: 0) {
                VStack(spacing: 0) {
                    SettingsListItem(Localizations.launchTutorial) {
                        store.send(.tutorialTapped)
                    }

                    externalLinkRow(Localizations.bitwardenHelpCenter, action: .helpCenterTapped, hasDivider: false)
                }
                .cornerRadius(10)
            }
            .padding(.bottom, 32)

            SectionView(Localizations.about, contentSpacing: 0) {
                VStack(spacing: 0) {
                    externalLinkRow(Localizations.privacyPolicy, action: .privacyPolicyTapped)

                    SettingsListItem(store.state.version, hasDivider: false) {
                        store.send(.versionTapped)
                    } trailingContent: {
                        Asset.Images.copy.swiftUIImage
                            .imageStyle(.rowIcon)
                    }
                }
                .cornerRadius(10)
            }
            .padding(.bottom, 16)

            copyrightNotice
        }
        .cornerRadius(10)
    }

    /// The application's default save option picker view
    @ViewBuilder private var defaultSaveOption: some View {
        SettingsMenuField(
            title: Localizations.defaultSaveOption,
            options: DefaultSaveOption.allCases,
            hasDivider: false,
            selection: store.binding(
                get: \.defaultSaveOption,
                send: SettingsAction.defaultSaveChanged
            )
        )
        .accessibilityIdentifier("DefaultSaveOptionChooser")
    }

    /// The application's color theme picker view
    private var theme: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsMenuField(
                title: Localizations.theme,
                options: AppTheme.allCases,
                hasDivider: false,
                selection: store.binding(
                    get: \.appTheme,
                    send: SettingsAction.appThemeChanged
                )
            )
            .cornerRadius(10)
            .accessibilityIdentifier("ThemeChooser")

            Text(Localizations.themeDescription)
                .styleGuide(.subheadline)
                .foregroundColor(Color(asset: Asset.Colors.textSecondary))
        }
    }

    /// A toggle for the user's biometric unlock preference.
    ///
    @ViewBuilder
    private func biometricUnlockToggle(enabled: Bool, type: BiometricAuthenticationType) -> some View {
        let toggleText = biometricsToggleText(type)
        Toggle(isOn: store.bindingAsync(
            get: { _ in enabled },
            perform: SettingsEffect.toggleUnlockWithBiometrics
        )) {
            Text(toggleText)
        }
        .padding(.trailing, 3)
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

    /// Returns a `SettingsListItem` configured for an external web link.
    ///
    /// - Parameters:
    ///   - name: The localized name of the row.
    ///   - action: An action to send when the row is tapped.
    /// - Returns: A `SettingsListItem` configured for an external web link.
    ///
    private func externalLinkRow(
        _ name: String,
        action: SettingsAction,
        hasDivider: Bool = true
    ) -> some View {
        SettingsListItem(name, hasDivider: hasDivider) {
            store.send(action)
        } trailingContent: {
            Asset.Images.externalLink2.swiftUIImage
                .imageStyle(.rowIcon)
        }
    }

    /// The settings row for syncing with the Password Manager app.
    private func syncWithPasswordManagerRow(hasDivider: Bool) -> some View {
        Button {
            store.send(.syncWithBitwardenAppTapped)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Localizations.syncWithBitwardenApp)
                            .styleGuide(.body)
                            .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                        Text(LocalizedStringKey(
                            Localizations.learnMoreLink(
                                ExternalLinksConstants.totpSyncHelp
                            )
                        ))
                        .styleGuide(.subheadline)
                        .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                        .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                    Asset.Images.externalLink2.swiftUIImage
                        .imageStyle(.rowIcon)
                }
                .padding(16)

                if hasDivider {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }
}

// MARK: - Previews

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(
                store: Store(
                    processor: StateProcessor(
                        state: SettingsState(
                            biometricUnlockStatus: .available(
                                .faceID,
                                enabled: false,
                                hasValidIntegrity: true
                            )
                        )
                    )
                )
            )
        }.previewDisplayName("SettingsView")

        NavigationView {
            SettingsView(
                store: Store(
                    processor: StateProcessor(
                        state: SettingsState(
                            shouldShowDefaultSaveOption: true
                        )
                    )
                )
            )
        }.previewDisplayName("With Default Save Option")
    }
}
#endif
