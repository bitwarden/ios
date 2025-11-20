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

    /// How the screen title is displayed, which depends on iOS version.
    private var titleDisplayMode: NavigationBarItem.TitleDisplayMode {
        if #available(iOS 26, *) {
            .inline
        } else {
            .large
        }
    }

    // MARK: View

    var body: some View {
        VStack(spacing: 16) {
            securitySection
            dataSection
            appearanceSection
            helpSection
            aboutSection
            copyrightNotice
        }
        .scrollView()
        .navigationBar(title: Localizations.settings, titleDisplayMode: titleDisplayMode)
        .toast(store.binding(
            get: \.toast,
            send: SettingsAction.toastShown,
        ))
        .onChange(of: store.state.url) { newValue in
            guard let url = newValue else { return }
            openURL(url)
            store.send(.clearURL)
        }
        .task {
            await store.perform(.loadData)
        }
        .task {
            await store.perform(.streamFlightRecorderLog)
        }
    }

    // MARK: Private views

    /// The about section containing privacy policy and version information.
    @ViewBuilder private var aboutSection: some View {
        SectionView(Localizations.about, contentSpacing: 8) {
            FlightRecorderSettingsSectionView(
                store: store.child(
                    state: \.flightRecorderState,
                    mapAction: { .flightRecorder($0) },
                    mapEffect: { .flightRecorder($0) },
                ),
            )

            ContentBlock(dividerLeadingPadding: 16) {
                externalLinkRow(Localizations.privacyPolicy, action: .privacyPolicyTapped)

                SettingsListItem(store.state.version) {
                    store.send(.versionTapped)
                } trailingContent: {
                    SharedAsset.Icons.copy24.swiftUIImage
                        .imageStyle(.rowIcon)
                }
            }
        }
    }

    /// The appearance section containing language and theme settings.
    @ViewBuilder private var appearanceSection: some View {
        SectionView(Localizations.appearance, contentSpacing: 8) {
            language
            theme
        }
    }

    /// The copyright notice.
    private var copyrightNotice: some View {
        Text(store.state.copyrightText)
            .styleGuide(.caption2)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    /// The data section containing import, export, backup, and sync options.
    @ViewBuilder private var dataSection: some View {
        SectionView(Localizations.data) {
            ContentBlock(dividerLeadingPadding: 16) {
                SettingsListItem(Localizations.import) {
                    store.send(.importItemsTapped)
                }

                SettingsListItem(Localizations.export) {
                    store.send(.exportItemsTapped)
                }

                SettingsListItem(Localizations.backup) {
                    store.send(.backupTapped)
                }

                syncWithPasswordManagerRow

                if store.state.shouldShowDefaultSaveOption {
                    defaultSaveOption
                }
            }
        }
    }

    /// The help section containing tutorial and help center links.
    @ViewBuilder private var helpSection: some View {
        SectionView(Localizations.help) {
            ContentBlock(dividerLeadingPadding: 16) {
                SettingsListItem(Localizations.launchTutorial) {
                    store.send(.tutorialTapped)
                }

                externalLinkRow(Localizations.bitwardenHelpCenter, action: .helpCenterTapped)
            }
        }
    }

    /// The language picker view.
    private var language: some View {
        Button {
            store.send(.languageTapped)
        } label: {
            BitwardenField(
                title: Localizations.language,
                footer: Localizations.languageChangeRequiresAppRestart,
            ) {
                Text(store.state.currentLanguage.title)
                    .styleGuide(.body)
                    .foregroundColor(Color(asset: SharedAsset.Colors.textPrimary))
                    .multilineTextAlignment(.leading)
            } accessoryContent: {
                SharedAsset.Icons.chevronDown24.swiftUIImage
                    .imageStyle(.rowIcon)
            }
        }
    }

    /// The application's default save option picker view.
    @ViewBuilder private var defaultSaveOption: some View {
        BitwardenMenuField(
            title: Localizations.defaultSaveOption,
            options: DefaultSaveOption.allCases,
            selection: store.binding(
                get: \.defaultSaveOption,
                send: SettingsAction.defaultSaveChanged,
            ),
        )
        .accessibilityIdentifier("DefaultSaveOptionChooser")
    }

    /// The security section containing biometric unlock and session timeout settings.
    @ViewBuilder private var securitySection: some View {
        switch store.state.biometricUnlockStatus {
        case let .available(type, enabled: enabled, _):
            SectionView(Localizations.security) {
                ContentBlock {
                    biometricUnlockToggle(enabled: enabled, type: type)

                    BitwardenMenuField(
                        title: Localizations.sessionTimeout,
                        accessibilityIdentifier: "VaultTimeoutChooser",
                        options: SessionTimeoutValue.allCases,
                        selection: store.bindingAsync(
                            get: \.sessionTimeoutValue,
                            perform: SettingsEffect.sessionTimeoutValueChanged,
                        ),
                    )
                }
            }
        default:
            EmptyView()
        }
    }

    /// The settings row for syncing with the Password Manager app.
    private var syncWithPasswordManagerRow: some View {
        Button {
            store.send(.syncWithBitwardenAppTapped)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localizations.syncWithBitwardenApp)
                        .styleGuide(.body)
                        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)

                    Text(LocalizedStringKey(
                        Localizations.learnMoreLink(
                            ExternalLinksConstants.totpSyncHelp,
                        ),
                    ))
                    .styleGuide(.subheadline, weight: .semibold)
                    .foregroundColor(Asset.Colors.textSecondary.swiftUIColor)
                    .tint(Asset.Colors.primaryBitwarden.swiftUIColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

                SharedAsset.Icons.externalLink16.swiftUIImage
                    .imageStyle(.rowIcon)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Asset.Colors.backgroundPrimary.swiftUIColor)
    }

    /// The application's color theme picker view.
    private var theme: some View {
        BitwardenMenuField(
            title: Localizations.theme,
            footer: Localizations.themeDescription,
            accessibilityIdentifier: "ThemeChooser",
            options: AppTheme.allCases,
            selection: store.binding(
                get: \.appTheme,
                send: SettingsAction.appThemeChanged,
            ),
        )
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
                perform: SettingsEffect.toggleUnlockWithBiometrics,
            ),
        )
        .accessibilityIdentifier("UnlockWithBiometricsSwitch")
        .accessibilityLabel(toggleText)
    }

    private func biometricsToggleText(_ biometryType: BiometricAuthenticationType) -> String {
        switch biometryType {
        case .faceID:
            Localizations.unlockWithFaceID
        case .touchID:
            Localizations.unlockWithTouchID
        }
    }

    /// Returns a `SettingsListItem` configured for an external web link.
    ///
    /// - Parameters:
    ///   - name: The localized name of the row.
    ///   - action: An action to send when the row is tapped.
    /// - Returns: A `SettingsListItem` configured for an external web link.
    ///
    private func externalLinkRow(_ name: String, action: SettingsAction) -> some View {
        SettingsListItem(name) {
            store.send(action)
        } trailingContent: {
            SharedAsset.Icons.externalLink24.swiftUIImage
                .imageStyle(.rowIcon)
        }
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
                                hasValidIntegrity: true,
                            ),
                        ),
                    ),
                ),
            )
        }.previewDisplayName("SettingsView")

        NavigationView {
            SettingsView(
                store: Store(
                    processor: StateProcessor(
                        state: SettingsState(
                            shouldShowDefaultSaveOption: true,
                        ),
                    ),
                ),
            )
        }.previewDisplayName("With Default Save Option")
    }
}
#endif
