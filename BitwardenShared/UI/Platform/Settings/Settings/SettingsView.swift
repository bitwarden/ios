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
            .navigationBar(title: Localizations.settings, titleDisplayMode: .large)
    }

    // MARK: Private views

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.chevronRight16)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
    }

    /// The settings items.
    private var settingsItems: some View {
        VStack(spacing: 0) {
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

            SettingsListItem(
                Localizations.appearance, icon: Asset.Images.paintBrush
            ) {
                store.send(.appearancePressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AppearanceSettingsButton")

            SettingsListItem(Localizations.other, icon: Asset.Images.other) {
                store.send(.otherPressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("OtherSettingsButton")

            SettingsListItem(
                Localizations.about,
                hasDivider: false,
                icon: Asset.Images.informationCircle24
            ) {
                store.send(.aboutPressed)
            } trailingContent: {
                chevron
            }
            .accessibilityIdentifier("AboutSettingsButton")
        }
        .cornerRadius(10)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    NavigationView {
        SettingsView(store: Store(processor: StateProcessor(state: SettingsState())))
    }
}
#endif
