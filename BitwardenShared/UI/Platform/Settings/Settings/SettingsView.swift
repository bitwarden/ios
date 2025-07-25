import BitwardenResources
import SwiftUI

// MARK: - SettingsView

/// A view containing the top-level list of settings.
///
struct SettingsView: View {
    // MARK: Properties

    /// The `Store` for this view.
    @ObservedObject var store: Store<SettingsState, SettingsAction, Void>

    // MARK: View

    var body: some View {
        settingsItems
            .scrollView()
            .navigationBar(title: Localizations.settings, titleDisplayMode: .inline)
            .toolbar {
                closeToolbarItem(hidden: store.state.presentationMode != .preLogin) {
                    store.send(.dismiss)
                }

                largeNavigationTitleToolbarItem(
                    Localizations.settings,
                    hidden: store.state.presentationMode != .tab
                )
            }
    }

    // MARK: Private views

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.chevronRight16)
            .foregroundColor(Color(asset: SharedAsset.Colors.textSecondary))
    }

    /// The settings items.
    private var settingsItems: some View {
        ContentBlock(dividerLeadingPadding: 48) {
            if store.state.presentationMode == .preLogin {
                appearanceRow
                aboutRow
            } else {
                accountSecurityRow
                autofillRow
                vaultRow
                appearanceRow
                otherRow
                aboutRow
            }
        }
    }

    // MARK: Settings Rows

    /// The about settings row.
    private var aboutRow: some View {
        SettingsListItem(
            Localizations.about,
            icon: Asset.Images.informationCircle24
        ) {
            store.send(.aboutPressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("AboutSettingsButton")
    }

    /// The account security settings row.
    private var accountSecurityRow: some View {
        SettingsListItem(
            Localizations.accountSecurity,
            badgeValue: store.state.accountSecurityBadgeValue,
            icon: Asset.Images.locked24
        ) {
            store.send(.accountSecurityPressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("AccountSecuritySettingsButton")
    }

    /// The appearance settings row.
    private var appearanceRow: some View {
        SettingsListItem(Localizations.appearance, icon: Asset.Images.paintBrush) {
            store.send(.appearancePressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("AppearanceSettingsButton")
    }

    /// The autofill settings row.
    private var autofillRow: some View {
        SettingsListItem(
            Localizations.autofill,
            badgeValue: store.state.autofillBadgeValue,
            icon: Asset.Images.checkCircle24
        ) {
            store.send(.autoFillPressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("AutofillSettingsButton")
    }

    /// The other settings row.
    private var otherRow: some View {
        SettingsListItem(Localizations.other, icon: Asset.Images.other) {
            store.send(.otherPressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("OtherSettingsButton")
    }

    /// The vault settings row.
    private var vaultRow: some View {
        SettingsListItem(
            Localizations.vault,
            badgeValue: store.state.vaultBadgeValue,
            icon: Asset.Images.vaultSettings
        ) {
            store.send(.vaultPressed)
        } trailingContent: {
            chevron
        }
        .accessibilityIdentifier("VaultSettingsButton")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Tab") {
    NavigationView {
        SettingsView(store: Store(processor: StateProcessor(state: SettingsState())))
    }
}

#Preview("Pre-login") {
    NavigationView {
        SettingsView(store: Store(processor: StateProcessor(state: SettingsState(presentationMode: .preLogin))))
    }
}
#endif
