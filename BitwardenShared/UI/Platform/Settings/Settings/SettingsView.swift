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
        ScrollView {
            VStack {
                settingsItems
            }
            .padding(16)
        }
        .background(Asset.Colors.backgroundSecondary.swiftUIColor.ignoresSafeArea())
        .navigationTitle(Localizations.settings)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Private views

    /// The chevron shown in the settings list item.
    private var chevron: some View {
        Image(asset: Asset.Images.rightAngle)
            .resizable()
            .frame(width: 12, height: 12)
            .foregroundColor(Color(asset: Asset.Colors.textSecondary))
    }

    /// The settings items.
    private var settingsItems: some View {
        VStack(spacing: 0) {
            SettingsListItem(Localizations.accountSecurity) {
                store.send(.accountSecurityPressed)
            } trailingContent: {
                chevron
            }

            SettingsListItem(Localizations.autofill) {
                store.send(.autoFillPressed)
            } trailingContent: {
                chevron
            }

            SettingsListItem(Localizations.vault) {} trailingContent: {
                chevron
            }

            SettingsListItem(Localizations.appearance) {} trailingContent: {
                chevron
            }

            SettingsListItem(Localizations.other) {} trailingContent: {
                chevron
            }

            SettingsListItem(Localizations.about, hasDivider: false) {} trailingContent: {
                chevron
            }
        }
        .cornerRadius(10)
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(store: Store(processor: StateProcessor(state: SettingsState())))
        }
    }
}
